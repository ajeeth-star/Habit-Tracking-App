import Foundation
import SwiftData
import Testing
import UIKit
@testable import HabitApp

/// Reminder planning (context.md §7) and the reminders-phase fixes: brand-new streak edits, misses that survive
/// deleting, time zones and daylight saving, and saved-data versions.
@MainActor
struct RemindersAndFixesTests {
    private let calendar = Calendar.current
    private let format = Formatters(locale: Locale(identifier: "en_US"))

    /// October 2026, local time. October 5 is a Monday.
    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    private func midnight(_ day: Int) -> Date { date(day, 0) }

    /// Apple's formatters use narrow no-break spaces ("8:00 PM"); compare them as normal spaces.
    private func plain(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{202F}", with: " ").replacingOccurrences(of: "\u{2009}", with: " ")
    }

    private func streak(_ start: TimeOfDay, _ end: TimeOfDay, name: String = "Gym",
                        days: Set<Weekday> = Set(Weekday.allCases), skips: Int = 1, created: Date? = nil) -> StreakData {
        StreakData(id: UUID(), name: name, color: .coral, icon: "dumbbell.fill", createdAt: created ?? date(1, 6),
                   versions: [ScheduleData(weekdays: days, window: TimeWindow(start: start, end: end),
                                           skipsPerWeek: skips, effectiveFrom: midnight(1))])
    }

    private func planner(repeat repeatMinutes: Int = 15, lastCall: Int = 15) -> ReminderPlanner {
        ReminderPlanner(rules: StreakRules(calendar: calendar), format: format, repeatMinutes: repeatMinutes,
                        lastCallMinutes: lastCall)
    }

    /// Today's reminders only (October 5).
    private func today(_ plan: [PlannedReminder], day: Int = 5) -> [PlannedReminder] {
        plan.filter { calendar.isDate($0.date, inSameDayAs: midnight(day)) }
    }

    // MARK: Reminder planning

    @Test func opensRepeatsAndLastCall() {
        let gym = streak(TimeOfDay(18), TimeOfDay(20))
        let plan = today(planner().plan([gym], now: date(5, 17)))
        let kinds: [PlannedReminder.Kind] = [.opens] + Array(repeating: .repeating, count: 6) + [.lastCall]
        #expect(plan.map(\.kind) == kinds)
        let times = plan.map { TimeOfDay($0.date, calendar: calendar) }
        let expected = [TimeOfDay(18), TimeOfDay(18, 15), TimeOfDay(18, 30), TimeOfDay(18, 45), TimeOfDay(19),
                        TimeOfDay(19, 15), TimeOfDay(19, 30), TimeOfDay(19, 45)]
        #expect(times == expected)
        #expect(plain(plan[0].title) == "Gym is open")
        #expect(plain(plan[0].body) == "Until 8:00 PM. Snap a photo to keep your streak going.")
        #expect(plain(plan[1].title) == "Gym · 1h 45m left")
        #expect(plain(plan[1].body) == "Your window closes at 8:00 PM.")
        #expect(plain(plan[7].title) == "Gym closes at 8:00 PM")
        #expect(plain(plan[7].body) == "Check in or use a skip (1 left).")
        #expect(plan[7].isTimeSensitive)
        #expect(!plan[1].isTimeSensitive)
        let allGyms = plan.allSatisfy { $0.id.hasPrefix(PlannedReminder.prefix(for: gym.id)) }
        #expect(allGyms)
    }

    @Test func noRepeatWithinFiveMinutesOfTheLastCall() {
        // Last call at 7:48; the 7:45 repeat would land 3 minutes before it.
        let plan = today(planner().plan([streak(TimeOfDay(18), TimeOfDay(20, 3))], now: date(5, 17)))
        let repeats = plan.filter { $0.kind == .repeating }.map { calendar.component(.minute, from: $0.date) }
        #expect(repeats.last == 30)
        #expect(plan.last?.kind == .lastCall)
        #expect(calendar.component(.minute, from: plan.last!.date) == 48)
    }

    @Test func settingsChangeTheSchedule() {
        let gym = streak(TimeOfDay(18), TimeOfDay(20))
        let every30 = today(planner(repeat: 30, lastCall: 30).plan([gym], now: date(5, 17)))
        #expect(every30.filter { $0.kind == .repeating }.count == 2) // 6:30, 7:00 (7:30 is the last call)
        #expect(calendar.component(.minute, from: every30.last!.date) == 30)
        let every10 = today(planner(repeat: 10, lastCall: 10).plan([gym], now: date(5, 17)))
        #expect(every10.filter { $0.kind == .repeating }.count == 10) // 6:10 … 7:40
    }

    @Test func onlyRemindersStillAheadAreScheduled() {
        let plan = today(planner().plan([streak(TimeOfDay(18), TimeOfDay(20))], now: date(5, 18, 20)))
        #expect(plan.first?.kind == .repeating)
        #expect(calendar.component(.minute, from: plan.first!.date) == 30)
    }

    @Test func doneOrSkippedStreaksGetNoMoreRemindersToday() {
        var done = streak(TimeOfDay(18), TimeOfDay(20))
        done.checkIns = [CheckInData(id: UUID(), day: midnight(5), time: date(5, 18, 5), photoFileName: "x.jpg")]
        var skipped = streak(TimeOfDay(18), TimeOfDay(20), name: "Run")
        skipped.skips = [SkipData(id: UUID(), day: midnight(5), time: date(5, 10), refunded: false)]
        let plan = planner().plan([done, skipped], now: date(5, 18, 10))
        #expect(today(plan).isEmpty)
        #expect(!today(plan, day: 6).isEmpty, "Tomorrow still reminds")
    }

    @Test func restDaysAndArchivedStreaksDontRemind() {
        let mondays = streak(TimeOfDay(18), TimeOfDay(20), days: [.monday])
        let plan = planner().plan([mondays], now: date(5, 21))
        #expect(today(plan, day: 6).isEmpty && today(plan, day: 7).isEmpty)
        #expect(!today(plan, day: 12).isEmpty, "Next Monday")

        var archived = streak(TimeOfDay(18), TimeOfDay(20))
        archived.archives = [ArchivePeriod(archivedAt: date(4, 9), restoredAt: nil)]
        #expect(planner().plan([archived], now: date(5, 9)).isEmpty)
    }

    @Test func lastCallWording() {
        let noSkips = streak(TimeOfDay(18), TimeOfDay(20), skips: 0)
        #expect(plain(today(planner().plan([noSkips], now: date(5, 17))).last!.body) == "Last chance to check in today.")

        var withStreak = noSkips
        withStreak.checkIns = [3, 4].map {
            CheckInData(id: UUID(), day: midnight($0), time: date($0, 18, 30), photoFileName: "x.jpg")
        }
        #expect(plain(today(planner().plan([withStreak], now: date(5, 17))).last!.body)
            == "Last chance to keep your 2-day streak.")
    }

    @Test func aWindowTooShortForALastCallGetsOnlyTheOpening() {
        let plan = today(planner(lastCall: 15).plan([streak(TimeOfDay(18), TimeOfDay(18, 10))], now: date(5, 17)))
        #expect(plan.map(\.kind) == [.opens])
    }

    @Test func atMostSixtyFourSoonestFirst() {
        let streaks = (0..<10).map { streak(TimeOfDay(8), TimeOfDay(20), name: "S\($0)") }
        let plan = planner(repeat: 10).plan(streaks, now: date(5, 7))
        #expect(plan.count == ReminderPlanner.limit)
        #expect(plan.map(\.date) == plan.map(\.date).sorted())
        let allToday = plan.allSatisfy { calendar.isDate($0.date, inSameDayAs: midnight(5)) }
        #expect(allToday, "Today's fill the 64 first")
        #expect(Set(plan.map(\.id)).count == plan.count, "Every id is unique")
    }

    // MARK: Brand-new streaks

    private func makeRepository() throws -> (HabitRepository, URL) {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("Fixes-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let repository = HabitRepository(container: try ModelContainer.habitData(inMemory: true),
                                         photos: PhotoStore(folder: folder.appendingPathComponent("Photos")))
        return (repository, folder)
    }

    private let photo: UIImage = {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20), format: format).image { _ in }
    }()

    private func draft(_ name: String, _ days: Set<Weekday>, _ start: Int, _ end: Int, skips: Int = 1) -> StreakDraft {
        StreakDraft(name: name, days: days, window: TimeWindow(start: TimeOfDay(start), end: TimeOfDay(end)),
                    skips: skips, color: .coral, icon: "dumbbell.fill")
    }

    @Test func editsApplyImmediatelyUntilTheFirstWindowOpens() throws {
        let (repository, _) = try makeRepository()
        let id = repository.create(draft("Gym", [.monday, .wednesday], 18, 20), now: date(5, 8))
        repository.update(id, with: draft("Gym", [.tuesday, .thursday], 12, 13, skips: 0), now: date(5, 10))
        let data = repository.record(id)!.data
        #expect(data.versions.count == 1)
        #expect(repository.rules.version(data, on: midnight(5))?.weekdays == [.tuesday, .thursday])
        #expect(repository.rules.version(data, on: midnight(5))?.skipsPerWeek == 0)
        #expect(repository.rules.version(data, on: midnight(5))?.window.start == TimeOfDay(12))

        // Tuesday's window has opened: days and skips now wait for next Monday.
        repository.update(id, with: draft("Gym", [.friday], 12, 13), now: date(6, 12, 30))
        let later = repository.record(id)!.data
        #expect(repository.rules.version(later, on: midnight(7))?.weekdays == [.tuesday, .thursday])
        #expect(repository.rules.version(later, on: midnight(12))?.weekdays == [.friday])
    }

    // MARK: Misses survive deleting and archiving

    /// Guitar (12–1) and Walk (6–8 PM), both checked in on Sunday: a 1-day streak going into Monday.
    private func twoStreaks() throws -> (HabitRepository, guitar: String, walk: String) {
        let (repository, _) = try makeRepository()
        let guitar = repository.create(draft("Guitar", Set(Weekday.allCases), 12, 13), now: date(4, 6))
        let walk = repository.create(draft("Walk", Set(Weekday.allCases), 18, 20), now: date(4, 6))
        try repository.checkIn(guitar, photo: photo, now: date(4, 12, 10))
        try repository.checkIn(walk, photo: photo, now: date(4, 18, 10))
        return (repository, guitar, walk)
    }

    @Test func aMissStillCountsAfterTheStreakIsDeleted() throws {
        let (repository, guitar, walk) = try twoStreaks()
        // Guitar's window closed at 1 PM with nothing done; it's deleted at 2.
        repository.delete(guitar, now: date(5, 14))
        try repository.checkIn(walk, photo: photo, now: date(5, 18, 30))
        let state = repository.dayStreakState(now: date(5, 18, 30))
        #expect(state.current == 0)
        #expect(state.lastBreak?.day == midnight(5))
        #expect(state.lastBreak?.length == 1)
    }

    @Test func aMissStillCountsAfterTheStreakIsArchived() throws {
        let (repository, guitar, walk) = try twoStreaks()
        repository.archive(guitar, now: date(5, 14))
        try repository.checkIn(walk, photo: photo, now: date(5, 18, 30))
        #expect(repository.dayStreakState(now: date(5, 18, 30)).current == 0)
    }

    @Test func deletingBeforeTheWindowClosesIsNotAMiss() throws {
        let (repository, guitar, walk) = try twoStreaks()
        repository.delete(guitar, now: date(5, 12, 30)) // window still open
        try repository.checkIn(walk, photo: photo, now: date(5, 18, 30))
        #expect(repository.dayStreakState(now: date(5, 18, 30)).current == 2)
    }

    @Test func aDayAlreadyCountedStaysCountedAfterDeleting() throws {
        let (repository, guitar, walk) = try twoStreaks()
        // Guitar skipped, Walk checked in: the day counts (+1 → 2).
        #expect(repository.skip(guitar, now: date(5, 11)))
        try repository.checkIn(walk, photo: photo, now: date(5, 18, 10))
        repository.catchUp(now: date(5, 18, 11))
        #expect(repository.dayStreakState(now: date(5, 18, 11)).current == 2)
        // Without Walk the day would be all skips, but the +1 it earned stays.
        repository.delete(walk, now: date(5, 19))
        #expect(repository.dayStreakState(now: date(5, 19)).current == 2)
        repository.catchUp(now: date(6, 9))
        #expect(repository.dayResults().first { $0.day == midnight(5) }?.kind == DayResultKind.counted.rawValue)
    }

    // MARK: Time zones and daylight saving

    @Test func aWindowSkippedByDaylightSavingIsNotJudged() {
        var losAngeles = Calendar(identifier: .gregorian)
        losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let rules = StreakRules(calendar: losAngeles)
        // March 14, 2027: clocks jump from 2:00 to 3:00 AM.
        let springForward = losAngeles.date(from: DateComponents(year: 2027, month: 3, day: 14))!
        let created = losAngeles.date(from: DateComponents(year: 2027, month: 3, day: 1))!
        func night(_ start: TimeOfDay, _ end: TimeOfDay) -> StreakData {
            StreakData(id: UUID(), name: "Night", color: .blue, icon: "moon.fill", createdAt: created,
                       versions: [ScheduleData(weekdays: Set(Weekday.allCases), window: TimeWindow(start: start, end: end),
                                               skipsPerWeek: 0, effectiveFrom: created)])
        }
        #expect(!rules.isJudged(night(TimeOfDay(2), TimeOfDay(2, 30)), on: springForward), "That window never happened")
        let later = losAngeles.date(byAdding: .day, value: 2, to: springForward)!
        #expect(rules.outcome(night(TimeOfDay(2), TimeOfDay(2, 30)), on: springForward, now: later) == nil)
        #expect(rules.isJudged(night(TimeOfDay(2), TimeOfDay(4)), on: springForward), "Partly there: still counts")
        #expect(rules.isJudged(night(TimeOfDay(2), TimeOfDay(2, 30)), on: losAngeles.date(byAdding: .day, value: 1,
                                                                                            to: springForward)!))
    }

    /// Flying from Los Angeles to New York: at 3 PM Pacific the phone changes zone and reads 6:10 PM Eastern.
    @Test func aWindowJumpedOverByATimeZoneChangeIsNotAMiss() {
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York")!
        let rules = StreakRules(calendar: newYork)
        func at(_ hour: Int, _ minute: Int) -> Date {
            newYork.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: hour, minute: minute))!
        }
        let created = newYork.date(from: DateComponents(year: 2026, month: 9, day: 28))!
        func window(_ name: String, _ start: TimeOfDay, _ end: TimeOfDay) -> StreakData {
            StreakData(id: UUID(), name: name, color: .blue, icon: "star.fill", createdAt: created,
                       versions: [ScheduleData(weekdays: Set(Weekday.allCases), window: TimeWindow(start: start, end: end),
                                               skipsPerWeek: 0, effectiveFrom: created)])
        }
        let jumped = window("Jumped", TimeOfDay(16), TimeOfDay(17))
        let stillOpen = window("Still open", TimeOfDay(17, 30), TimeOfDay(18, 30))
        let missedBefore = window("Missed before", TimeOfDay(12), TimeOfDay(13))
        let before = at(18, 0) // 3:00 PM Pacific
        let skipped = rules.windowsSkippedByClockJump([jumped, stillOpen, missedBefore], before: before,
                                                      beforeOffset: -7 * 3600, now: at(18, 10), nowOffset: -4 * 3600)
        #expect(skipped.map(\.streakID) == [jumped.id])
        #expect(skipped.first?.day == newYork.startOfDay(for: before))

        // Flying west never skips anything.
        #expect(rules.windowsSkippedByClockJump([jumped], before: at(18, 0), beforeOffset: -4 * 3600, now: at(21, 10),
                                                nowOffset: -7 * 3600).isEmpty)

        // Once recorded, the window simply doesn't count.
        var recorded = jumped
        recorded.skippedDays = [newYork.startOfDay(for: before)]
        #expect(rules.outcome(recorded, on: before, now: at(18, 10)) == nil)
    }

    @Test func theRepositoryRecordsWindowsATimeZoneChangeSkipped() throws {
        var losAngeles = Calendar(identifier: .gregorian)
        losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York")!
        func pacific(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            losAngeles.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
        }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("TZ-\(UUID().uuidString)")
        let repository = HabitRepository(container: try ModelContainer.habitData(inMemory: true),
                                         photos: PhotoStore(folder: folder), calendar: losAngeles)
        // A 4–5 PM streak, checked in on Sunday in Los Angeles.
        let id = repository.create(draft("Jumped", Set(Weekday.allCases), 16, 17), now: pacific(4, 8))
        try repository.checkIn(id, photo: photo, now: pacific(4, 16, 30))
        repository.catchUp(now: pacific(5, 15), offset: -7 * 3600)

        // Monday 3:10 PM Pacific: the phone switches to New York and reads 6:10 PM. 4–5 PM was jumped over.
        repository.rules.calendar = newYork
        repository.catchUp(now: pacific(5, 15, 10), offset: -4 * 3600)
        let data = try #require(repository.streaks().first)
        #expect(data.skippedDays == [newYork.startOfDay(for: pacific(5, 15, 10))])
        let summary = repository.rules.summary(data, now: pacific(6, 6))
        #expect(summary.ended == nil, "Not a miss")
        #expect(summary.current.totalCheckIns == 1, "Sunday's check-in still counts after the move")

        repository.catchUp(now: pacific(6, 6), offset: -4 * 3600)
        let monday = repository.dayResults().first { newYork.savedDay($0.day) == newYork.startOfDay(for: pacific(5, 15)) }
        #expect(monday?.kind == DayResultKind.rest.rawValue)
    }

    // MARK: Saved-data versions

    @Test func dataSavedWithVersionOneLoadsInTheCurrentVersion() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("V1-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("data.store")
        let streakID = UUID()
        do {
            let v1 = Schema(versionedSchema: SchemaV1.self)
            let container = try ModelContainer(for: v1, configurations: ModelConfiguration(schema: v1, url: url))
            let context = container.mainContext
            let streak = SchemaV1.StreakRecord(id: streakID, name: "Gym", colorKey: "coral", iconName: "dumbbell.fill",
                                               createdAt: date(5, 8))
            context.insert(streak)
            let version = SchemaV1.ScheduleVersionRecord(weekdays: [1, 3], startMinute: 18 * 60, endMinute: 20 * 60,
                                                         skipsPerWeek: 1, effectiveFrom: midnight(5))
            context.insert(version)
            version.streak = streak
            let checkIn = SchemaV1.CheckInRecord(day: midnight(5), time: date(5, 18, 30), photoFileName: "a.jpg")
            context.insert(checkIn)
            checkIn.streak = streak
            let app = SchemaV1.AppRecord()
            app.longestDayStreak = 12
            context.insert(app)
            context.insert(SchemaV1.DayResultRecord(day: midnight(4), kind: DayResultKind.counted.rawValue, missedAt: nil))
            try context.save()
        }

        let repository = HabitRepository(container: try ModelContainer.habitData(url: url),
                                         photos: PhotoStore(folder: folder.appendingPathComponent("Photos")))
        let record = try #require(repository.record(streakID.uuidString))
        #expect(record.name == "Gym")
        #expect(record.versions.first?.weekdays == [1, 3])
        #expect(record.checkIns.first?.time == date(5, 18, 30))
        #expect(record.skippedWindows.isEmpty)
        #expect(repository.appRecord.longestDayStreak == 12)
        #expect(repository.appRecord.lastSeenOffset == nil)
        #expect(repository.dayResults().count == 1)
    }
}
