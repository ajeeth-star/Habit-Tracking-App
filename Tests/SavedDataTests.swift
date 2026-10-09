import Foundation
import SwiftData
import Testing
import UIKit
@testable import HabitApp

/// Saved data (context.md §11): saving and reloading, schedule versions, catching up on days that passed,
/// and photo files. Each test gets its own temporary saved data and photo folder.
@MainActor
struct SavedDataTests {
    private let folder: URL
    private let photos: PhotoStore
    private let calendar = Calendar.current

    init() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent("SavedDataTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        photos = PhotoStore(folder: folder.appendingPathComponent("Photos"))
    }

    private var storeURL: URL { folder.appendingPathComponent("data.store") }

    private func makeRepository() throws -> HabitRepository {
        HabitRepository(container: try ModelContainer.habitData(url: storeURL), photos: photos)
    }

    /// October 2026, local time. October 5 is a Monday.
    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    private func midnight(_ day: Int) -> Date { date(day, 0) }

    /// A big photo, so resizing shows.
    private let photo: UIImage = {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 4000, height: 3000), format: format).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4000, height: 3000))
        }
    }()

    private func draft(_ name: String, _ days: Set<Weekday>, _ start: Int, _ end: Int, skips: Int = 1) -> StreakDraft {
        StreakDraft(name: name, days: days, window: TimeWindow(start: TimeOfDay(start), end: TimeOfDay(end)),
                    skips: skips, color: .coral, icon: "dumbbell.fill")
    }

    private func streak(_ repository: HabitRepository, _ id: String) -> StreakData {
        repository.record(id)!.data
    }

    // MARK: Saving and reloading

    @Test func savesAndReloadsEveryModel() throws {
        let gymID: String
        do {
            let repository = try makeRepository()
            gymID = repository.create(draft("Gym", [.monday, .tuesday, .thursday, .friday], 18, 20), now: date(5, 9))
            try repository.checkIn(gymID, photo: photo, now: date(5, 18, 30))
            #expect(repository.skip(gymID, now: date(6, 10)))
            repository.update(gymID, with: draft("Gym!", [.monday, .tuesday, .thursday, .friday], 19, 21), now: date(6, 10))
            repository.update(gymID, with: draft("Gym!", [.monday, .friday], 19, 21, skips: 0), now: date(6, 11))
            repository.archive(gymID, now: date(7, 8))
            repository.restore(gymID, now: date(7, 9))
            repository.catchUp(now: date(8, 10))
            repository.markEndedScreenShown(forBreakOn: midnight(5))
        }

        // A brand-new container on the same file: everything comes back.
        let reloaded = try makeRepository()
        let record = try #require(reloaded.record(gymID))
        #expect(record.name == "Gym!")
        #expect(record.colorKey == StreakColor.coral.rawValue)
        #expect(record.iconName == "dumbbell.fill")
        #expect(record.createdAt == date(5, 9))
        #expect(record.archivedAt == nil)
        #expect(record.pastArchivedAt == [date(7, 8)])
        #expect(record.pastRestoredAt == [date(7, 9)])

        let versions = record.versions.sorted { $0.effectiveFrom < $1.effectiveFrom }
        #expect(versions.map(\.effectiveFrom) == [midnight(5), midnight(6), midnight(12)])
        #expect(versions[1].startMinute == 19 * 60 && versions[1].endMinute == 21 * 60)
        #expect(versions[2].weekdays == [1, 5] && versions[2].skipsPerWeek == 0 && versions[2].startMinute == 19 * 60)

        let checkIn = try #require(record.checkIns.first)
        #expect(checkIn.day == midnight(5) && checkIn.time == date(5, 18, 30))
        let saved = try #require(photos.image(checkIn.photoFileName))
        #expect(max(saved.size.width, saved.size.height) == PhotoStore.maxSide)

        let skip = try #require(record.skips.first)
        #expect(skip.day == midnight(6) && skip.time == date(6, 10) && !skip.refunded)

        #expect(reloaded.dayResults().map(\.day) == [midnight(5), midnight(6), midnight(7)])
        #expect(reloaded.appRecord.lastProcessedDay == midnight(7))
        #expect(reloaded.appRecord.endedScreenShownForBreak == midnight(5))
    }

    // MARK: Schedule versions

    @Test func daysAndSkipsChangesStartNextMondayAndPastDaysKeepTheOldVersion() throws {
        let repository = try makeRepository()
        let rules = repository.rules
        let id = repository.create(draft("Guitar", [.monday, .wednesday, .friday], 12, 13), now: date(5, 8))
        try repository.checkIn(id, photo: photo, now: date(5, 12, 10))
        repository.update(id, with: draft("Guitar", [.tuesday, .thursday], 12, 13, skips: 0), now: date(6, 9))

        // This week still runs on the old schedule; the form shows what's coming.
        let tuesday = rules.snapshot(streak(repository, id), now: date(6, 9))
        #expect(tuesday.days == [.monday, .wednesday, .friday])
        #expect(tuesday.skipsPerWeek == 1)
        #expect(tuesday.nextWeek == NextWeekChange(days: [.tuesday, .thursday], skipsPerWeek: 0))
        #expect(tuesday.today == .notToday(next: .tomorrow))

        // Wednesday is missed under the old schedule, and stays missed when looked at later.
        let later = date(14, 9)
        #expect(rules.outcome(streak(repository, id), on: midnight(7), now: later) == .missed)
        #expect(rules.outcome(streak(repository, id), on: midnight(6), now: later) == nil)
        #expect(rules.summary(streak(repository, id), now: date(8, 9)).ended?.day == midnight(7))

        // From Monday the new one applies: Tuesday counts, Monday doesn't.
        #expect(rules.isJudged(streak(repository, id), on: midnight(13)))
        #expect(!rules.isJudged(streak(repository, id), on: midnight(12)))
        #expect(rules.snapshot(streak(repository, id), now: date(12, 9)).skipsPerWeek == 0)
    }

    @Test func windowChangesApplyTodayOnlyBeforeTheWindowOpens() throws {
        let repository = try makeRepository()
        let rules = repository.rules
        let id = repository.create(draft("Run", Set(Weekday.allCases), 12, 13), now: date(5, 6))

        // Before noon: today's window moves.
        repository.update(id, with: draft("Run", Set(Weekday.allCases), 18, 19), now: date(6, 10))
        #expect(rules.version(streak(repository, id), on: midnight(6))?.window.start == TimeOfDay(18))

        // After it opened: from tomorrow, so a window that already started can't be moved out of the way.
        repository.update(id, with: draft("Run", Set(Weekday.allCases), 20, 21), now: date(7, 18, 30))
        #expect(rules.version(streak(repository, id), on: midnight(7))?.window.start == TimeOfDay(18))
        #expect(rules.version(streak(repository, id), on: midnight(8))?.window.start == TimeOfDay(20))
    }

    // MARK: Counting rules

    @Test func partialFirstWeekCountsAsAWeekOnceItsOver() throws {
        let repository = try makeRepository()
        let id = repository.create(draft("Gym", [.wednesday, .friday], 18, 20), now: date(7, 8))
        try repository.checkIn(id, photo: photo, now: date(7, 18, 30))
        try repository.checkIn(id, photo: photo, now: date(9, 18, 30))
        #expect(repository.rules.summary(streak(repository, id), now: date(9, 21)).current
            == Streak(weeks: 0, days: 2, totalCheckIns: 2))
        #expect(repository.rules.summary(streak(repository, id), now: date(12, 8)).current
            == Streak(weeks: 1, days: 0, totalCheckIns: 2))
    }

    @Test func aWeekOfOnlySkipsKeepsTheStreakButAddsNoWeek() throws {
        let repository = try makeRepository()
        let id = repository.create(draft("Guitar", [.monday, .wednesday], 12, 13, skips: 2), now: date(5, 8))
        #expect(repository.skip(id, now: date(5, 9)))
        #expect(repository.skip(id, now: date(7, 9)))
        let summary = repository.rules.summary(streak(repository, id), now: date(12, 8))
        #expect(summary.current == .zero)
        #expect(summary.ended == nil)
    }

    @Test func checkingInAfterASkipGivesItBack() throws {
        let repository = try makeRepository()
        let id = repository.create(draft("Run", Set(Weekday.allCases), 12, 13), now: date(5, 8))
        #expect(repository.skip(id, now: date(5, 11)))
        #expect(repository.rules.skipsLeft(streak(repository, id), now: date(5, 11)) == 0)
        #expect(!repository.skip(id, now: date(5, 11, 30)), "No skips left")
        try repository.checkIn(id, photo: photo, now: date(5, 12, 30))
        let data = streak(repository, id)
        let allRefunded = data.skips.allSatisfy(\.refunded)
        #expect(allRefunded)
        #expect(repository.rules.skipsLeft(data, now: date(5, 12, 31)) == 1)
        #expect(repository.rules.outcome(data, on: midnight(5), now: date(5, 13)) == .checkedIn(at: date(5, 12, 30)))
    }

    @Test func checkInsOnlyCountWhileTheWindowIsOpen() throws {
        let repository = try makeRepository()
        let id = repository.create(draft("Gym", Set(Weekday.allCases), 18, 20), now: date(5, 8))
        #expect(throws: HabitRepository.CheckInError.windowClosed) {
            try repository.checkIn(id, photo: photo, now: date(5, 17, 59))
        }
        #expect(throws: HabitRepository.CheckInError.windowClosed) {
            try repository.checkIn(id, photo: photo, now: date(5, 20))
        }
        try repository.checkIn(id, photo: photo, now: date(5, 18))
        #expect(throws: HabitRepository.CheckInError.alreadyDone) {
            try repository.checkIn(id, photo: photo, now: date(5, 19))
        }
        #expect(photos.usage().count == 1, "Rejected check-ins leave no photo behind")
    }

    @Test func aStreakCreatedDuringItsWindowStartsTomorrow() throws {
        let repository = try makeRepository()
        let id = repository.create(draft("Read", Set(Weekday.allCases), 12, 13), now: date(5, 12, 30))
        let data = streak(repository, id)
        #expect(!repository.rules.isJudged(data, on: midnight(5)))
        #expect(repository.rules.isJudged(data, on: midnight(6)))
        repository.catchUp(now: date(6, 8))
        #expect(repository.dayResults().first?.kind == DayResultKind.rest.rawValue)
    }

    @Test func archivingStopsCountingAndRestoringStartsFreshTomorrow() throws {
        let repository = try makeRepository()
        let rules = repository.rules
        let id = repository.create(draft("Gym", Set(Weekday.allCases), 18, 20), now: date(5, 8))
        try repository.checkIn(id, photo: photo, now: date(5, 18, 30))
        repository.archive(id, now: date(6, 19)) // during Tuesday's window: Tuesday doesn't count
        #expect(rules.outcome(streak(repository, id), on: midnight(6), now: date(9, 8)) == nil)
        repository.restore(id, now: date(8, 9)) // Thursday: counting starts Friday
        #expect(rules.outcome(streak(repository, id), on: midnight(8), now: date(9, 8)) == nil)
        #expect(rules.isJudged(streak(repository, id), on: midnight(9)))
        let summary = rules.summary(streak(repository, id), now: date(9, 8))
        #expect(summary.current == .zero)
        #expect(summary.longest.totalCheckIns == 1)
        #expect(summary.ended == nil)
    }

    // MARK: Catching up

    @Test func catchUpAcrossSeveralMissedDays() throws {
        let repository = try makeRepository()
        let id = repository.create(draft("Skincare", Set(Weekday.allCases), 7, 9), now: date(5, 6))
        try repository.checkIn(id, photo: photo, now: date(5, 7, 30))
        try repository.checkIn(id, photo: photo, now: date(6, 7, 30))
        // The app isn't opened again until Friday morning.
        repository.catchUp(now: date(9, 10))

        // Finished days only; today (a miss at 9 AM) is saved as a partial result too.
        let results = repository.dayResults().filter { $0.day < midnight(9) }
        #expect(results.map(\.day) == [midnight(5), midnight(6), midnight(7), midnight(8)])
        #expect(results.map(\.kind) == [DayResultKind.counted, .counted, .broken, .broken].map(\.rawValue))
        #expect(results[2].missedAt == date(7, 9))
        #expect(repository.appRecord.lastProcessedDay == midnight(8))

        let state = repository.dayStreakState(now: date(9, 10))
        #expect(state.current == 0)
        #expect(state.longest == 2)
        #expect(state.lastBreak?.day == midnight(7))
        #expect(state.lastBreak?.length == 2)
        #expect(state.needsEndedScreen)

        let summary = repository.rules.summary(streak(repository, id), now: date(9, 10))
        #expect(summary.longest.totalCheckIns == 2)
        #expect(summary.ended?.day == midnight(7))

        // Catching up again changes nothing.
        repository.catchUp(now: date(9, 11))
        #expect(repository.dayResults().count == 5) // 4 finished days + today so far
    }

    @Test func catchUpAcrossAWeekBoundary() throws {
        let repository = try makeRepository()
        let id = repository.create(draft("Walk", Set(Weekday.allCases), 7, 9), now: date(5, 6))
        for day in 5...11 { try repository.checkIn(id, photo: photo, now: date(day, 8)) }
        repository.catchUp(now: date(12, 6))

        let allCounted = repository.dayResults().allSatisfy { $0.kind == DayResultKind.counted.rawValue }
        #expect(allCounted)
        let state = repository.dayStreakState(now: date(12, 6))
        #expect(state.current == 7)
        #expect(state.form == .flame)
        #expect(repository.appRecord.bestFlameForm == FlameForm.flame.rawValue)
        #expect(repository.rules.summary(streak(repository, id), now: date(12, 6)).current
            == Streak(weeks: 1, days: 0, totalCheckIns: 7))
    }

    @Test func catchUpAfterMoreThanAWeekAway() throws {
        let repository = try makeRepository()
        let id = repository.create(draft("Walk", Set(Weekday.allCases), 7, 9), now: date(5, 6))
        try repository.checkIn(id, photo: photo, now: date(5, 8))
        repository.catchUp(now: date(20, 10))

        let results = repository.dayResults().filter { $0.day < midnight(20) }
        #expect(results.count == 15) // October 5–19
        #expect(results.first?.kind == DayResultKind.counted.rawValue)
        let restBroken = results.dropFirst().allSatisfy { $0.kind == DayResultKind.broken.rawValue }
        #expect(restBroken)
        #expect(repository.appRecord.lastProcessedDay == midnight(19))
        let state = repository.dayStreakState(now: date(20, 10))
        #expect(state.current == 0)
        #expect(state.longest == 1)
        #expect(state.lastBreak?.day == midnight(6))
    }

    @Test func deletingAStreakDoesntRewritePastDays() throws {
        let repository = try makeRepository()
        let missed = repository.create(draft("Guitar", Set(Weekday.allCases), 12, 13), now: date(5, 6))
        let kept = repository.create(draft("Walk", Set(Weekday.allCases), 7, 9), now: date(5, 6))
        for day in 5...7 { try repository.checkIn(kept, photo: photo, now: date(day, 8)) }
        try repository.checkIn(missed, photo: photo, now: date(5, 12, 30))
        repository.catchUp(now: date(8, 6))
        #expect(repository.dayResults().map(\.kind) == [DayResultKind.counted, .broken, .broken].map(\.rawValue))

        repository.delete(missed, now: date(8, 6))
        repository.catchUp(now: date(8, 6))
        #expect(repository.dayResults().map(\.kind) == [DayResultKind.counted, .broken, .broken].map(\.rawValue))
        #expect(repository.dayStreakState(now: date(8, 6)).lastBreak?.day == midnight(6))
        #expect(repository.dayStreakState(now: date(8, 6)).longest == 1)
    }

    // MARK: Photos

    @Test func deletingAStreakDeletesItsPhotoFiles() throws {
        let repository = try makeRepository()
        let gym = repository.create(draft("Gym", Set(Weekday.allCases), 18, 20), now: date(5, 8))
        let run = repository.create(draft("Run", Set(Weekday.allCases), 18, 20), now: date(5, 8))
        try repository.checkIn(gym, photo: photo, now: date(5, 18, 30))
        try repository.checkIn(run, photo: photo, now: date(5, 18, 40))
        let gymFile = try #require(repository.record(gym)?.checkIns.first?.photoFileName)
        let runFile = try #require(repository.record(run)?.checkIns.first?.photoFileName)

        repository.archive(run, now: date(5, 19))
        #expect(photos.image(runFile) != nil, "Archiving keeps photos")

        repository.delete(gym, now: date(5, 19, 30))
        #expect(!FileManager.default.fileExists(atPath: photos.url(gymFile).path))
        #expect(FileManager.default.fileExists(atPath: photos.url(runFile).path))
        #expect(photos.usage().count == 1)
        #expect(photos.usage().bytes > 0)

        repository.deleteAll()
        #expect(photos.usage().count == 0)
        #expect(repository.streakRecords().isEmpty)
        #expect(repository.dayResults().isEmpty)
    }

    @Test func photosAreResizedJPEGs() throws {
        let data = try #require(PhotoStore.jpeg(photo))
        let image = try #require(UIImage(data: data))
        #expect(image.size == CGSize(width: 1600, height: 1200))
        #expect(data.starts(with: [0xFF, 0xD8]), "JPEG")
    }
}
