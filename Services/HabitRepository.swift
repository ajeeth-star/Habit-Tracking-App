import Foundation
import SwiftData
import UIKit

/// Reads and writes the saved records (context.md §11). Every change is saved straight away. Screens don't use
/// this directly: `TaskStore` turns its records into snapshots with `StreakRules`.
@MainActor
final class HabitRepository {
    /// Kept alive here: a context doesn't keep its container, and reading after the container is gone crashes.
    let container: ModelContainer
    let context: ModelContext
    let photos: PhotoStore
    /// Changeable so tests can move the phone to another time zone.
    var rules: StreakRules
    private var calendar: Calendar { rules.calendar }

    init(container: ModelContainer, photos: PhotoStore = .shared, calendar: Calendar = .autoupdatingCurrent) {
        self.container = container
        context = container.mainContext
        context.autosaveEnabled = false
        self.photos = photos
        rules = StreakRules(calendar: calendar)
    }

    // MARK: Reading

    func streakRecords() -> [StreakRecord] {
        (try? context.fetch(FetchDescriptor<StreakRecord>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
    }

    func streaks() -> [StreakData] { streakRecords().map { $0.data(calendar: calendar) } }

    func record(_ id: String) -> StreakRecord? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        var descriptor = FetchDescriptor<StreakRecord>(predicate: #Predicate { $0.id == uuid })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    /// The single app record, created the first time it's needed.
    var appRecord: AppRecord {
        if let existing = try? context.fetch(FetchDescriptor<AppRecord>()).first { return existing }
        let record = AppRecord()
        context.insert(record)
        return record
    }

    func dayResults() -> [DayResultRecord] {
        (try? context.fetch(FetchDescriptor<DayResultRecord>(sortBy: [SortDescriptor(\.day)]))) ?? []
    }

    // MARK: Streaks

    /// A new streak, its first schedule in effect from today. Returns its id.
    @discardableResult
    func create(_ draft: StreakDraft, now: Date) -> String {
        let record = StreakRecord(name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                                  colorKey: draft.color.rawValue, iconName: draft.icon, createdAt: now)
        context.insert(record)
        let version = ScheduleVersionRecord(
            weekdays: draft.days.map(\.rawValue).sorted(), startMinute: draft.window.start.minutesSinceMidnight,
            endMinute: draft.window.end.minutesSinceMidnight, skipsPerWeek: draft.skips,
            effectiveFrom: calendar.startOfDay(for: now))
        context.insert(version)
        version.streak = record
        save()
        return record.id.uuidString
    }

    /// Saves an edit (context.md §3, §11):
    /// - name, color, icon: straight away;
    /// - window: from today if today's window hasn't opened yet, otherwise from tomorrow;
    /// - days and skips: from next Monday;
    /// - all of it straight away while the streak is brand new (none of its windows has opened yet).
    func update(_ id: String, with draft: StreakDraft, now: Date) {
        guard let record = record(id) else { return }
        record.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        record.colorKey = draft.color.rawValue
        record.iconName = draft.icon

        if !rules.hasOpenedAWindow(record.data(calendar: calendar), now: now) {
            // No history to protect: the new schedule simply replaces the old one.
            for version in record.versions {
                version.weekdays = draft.days.map(\.rawValue).sorted()
                version.startMinute = draft.window.start.minutesSinceMidnight
                version.endMinute = draft.window.end.minutesSinceMidnight
                version.skipsPerWeek = draft.skips
            }
            save()
            return
        }

        let today = calendar.startOfDay(for: now)
        if let current = rules.version(record.data(calendar: calendar), on: today), current.window != draft.window {
            let opens = rules.window(current.window, on: today).opens
            let from = now < opens ? today : day(after: today)
            setVersion(of: record, from: from, alsoLater: true) {
                $0.startMinute = draft.window.start.minutesSinceMidnight
                $0.endMinute = draft.window.end.minutesSinceMidnight
            }
        }

        let nextMonday = calendar.date(byAdding: .day, value: 7, to: rules.startOfWeek(now)) ?? today
        if let pending = rules.version(record.data(calendar: calendar), on: nextMonday),
           pending.weekdays != draft.days || pending.skipsPerWeek != draft.skips {
            setVersion(of: record, from: nextMonday, alsoLater: false) {
                $0.weekdays = draft.days.map(\.rawValue).sorted()
                $0.skipsPerWeek = draft.skips
            }
        }
        save()
    }

    /// Changes the version starting at `from` (made from the one in effect then, if there isn't one yet),
    /// and with `alsoLater`, every version after it too.
    private func setVersion(of record: StreakRecord, from: Date, alsoLater: Bool,
                            change: (ScheduleVersionRecord) -> Void) {
        if let existing = record.versions.first(where: { calendar.savedDay($0.effectiveFrom) == from }) {
            change(existing)
        } else if let base = rules.version(record.data(calendar: calendar), on: from) {
            let version = ScheduleVersionRecord(
                weekdays: base.weekdays.map(\.rawValue).sorted(), startMinute: base.window.start.minutesSinceMidnight,
                endMinute: base.window.end.minutesSinceMidnight, skipsPerWeek: base.skipsPerWeek, effectiveFrom: from)
            context.insert(version)
            version.streak = record
            change(version)
        }
        if alsoLater {
            for later in record.versions where calendar.savedDay(later.effectiveFrom) > from { change(later) }
        }
    }

    /// Archives the streak. Today's misses so far are saved first, so archiving can't undo them.
    func archive(_ id: String, now: Date) {
        catchUp(now: now)
        guard let record = record(id), record.archivedAt == nil else { return }
        record.archivedAt = now
        save()
    }

    /// A fresh streak from its next scheduled day; days while it was archived aren't judged.
    func restore(_ id: String, now: Date) {
        guard let record = record(id), let archivedAt = record.archivedAt else { return }
        record.pastArchivedAt.append(archivedAt)
        record.pastRestoredAt.append(now)
        record.archivedAt = nil
        save()
    }

    /// Deletes the streak, its schedule, check-ins, skips, and photo files. Today's misses so far are saved first,
    /// and past day results stay as they were, so only windows that haven't closed yet are affected.
    func delete(_ id: String, now: Date) {
        catchUp(now: now)
        guard let record = record(id) else { return }
        photos.delete(record.checkIns.map(\.photoFileName))
        context.delete(record)
        save()
    }

    /// Every streak, photo, and record. Settings are kept.
    func deleteAll() {
        try? context.delete(model: StreakRecord.self)
        try? context.delete(model: ScheduleVersionRecord.self)
        try? context.delete(model: CheckInRecord.self)
        try? context.delete(model: SkipRecord.self)
        try? context.delete(model: DayResultRecord.self)
        try? context.delete(model: AppRecord.self)
        photos.deleteAll()
        save()
    }

    // MARK: Check-ins and skips

    enum CheckInError: Error { case windowClosed, notScheduled, alreadyDone }

    /// Saves a check-in with its photo, if today's window is open (`CheckInRule`). A skip used earlier today
    /// is given back.
    func checkIn(_ id: String, photo: UIImage, now: Date) throws {
        guard let record = record(id) else { throw CheckInError.notScheduled }
        try checkCanCheckIn(record, now: now)
        let fileName = try photos.save(photo)
        addCheckIn(to: record, at: now, photoFileName: fileName)
        save()
    }

    private func checkCanCheckIn(_ record: StreakRecord, now: Date) throws {
        let data = record.data(calendar: calendar)
        let today = calendar.startOfDay(for: now)
        guard !data.isArchived, rules.isJudged(data, on: today), let version = rules.version(data, on: today) else {
            throw CheckInError.notScheduled
        }
        if data.checkIns.contains(where: { $0.day == today }) { throw CheckInError.alreadyDone }
        let (opens, closes) = rules.window(version.window, on: today)
        guard CheckInRule.isAllowed(opens: opens, closes: closes, now: now) else { throw CheckInError.windowClosed }
    }

    private func addCheckIn(to record: StreakRecord, at time: Date, photoFileName: String) {
        let day = calendar.startOfDay(for: time)
        let checkIn = CheckInRecord(day: day, time: time, photoFileName: photoFileName)
        context.insert(checkIn)
        checkIn.streak = record
        for skip in record.skips where calendar.savedDay(skip.day) == day && !skip.refunded { skip.refunded = true }
    }

    /// Uses a skip for today: a scheduled day, before its window closes, nothing done yet, a skip left.
    @discardableResult
    func skip(_ id: String, now: Date) -> Bool {
        guard let record = record(id) else { return false }
        let data = record.data(calendar: calendar)
        let today = calendar.startOfDay(for: now)
        guard rules.outcome(data, on: today, now: now) == .pending, rules.skipsLeft(data, now: now) > 0 else {
            return false
        }
        let skip = SkipRecord(day: today, time: now)
        context.insert(skip)
        skip.streak = record
        save()
        return true
    }

    // MARK: Day streak

    /// Saves the result of every day since the last processed one, up to yesterday, in order. Then updates
    /// the longest day streak and best flame form.
    /// Brings saved data up to `now` (context.md §10–11):
    /// 1. notices a time zone change and records any window it jumped over;
    /// 2. saves the result of every day since the last processed one, up to yesterday, in order (a day that already
    ///    has a partial result from when it was "today" keeps its miss or +1);
    /// 3. saves what has already happened today (a miss, or the +1), so deleting or archiving can't undo it;
    /// 4. updates the longest day streak and best flame form.
    /// `offset` is the time zone's offset from GMT now (seconds); tests pass their own.
    func catchUp(now: Date, offset: Int? = nil) {
        let today = calendar.startOfDay(for: now)
        let yesterday = day(after: today, by: -1)
        let app = appRecord
        // The pretend clock went backwards (DEBUG): forget results from "today" on.
        if let last = app.lastProcessedDay.map(calendar.savedDay), last >= today {
            for result in dayResults() where calendar.savedDay(result.day) >= today { context.delete(result) }
            app.lastProcessedDay = yesterday
        }

        let offset = offset ?? calendar.timeZone.secondsFromGMT(for: now)
        if let lastSeen = app.lastSeenAt, let lastOffset = app.lastSeenOffset, lastOffset != offset, lastSeen < now {
            recordWindowsSkipped(before: lastSeen, beforeOffset: lastOffset, now: now, nowOffset: offset)
        }
        app.lastSeenAt = now
        app.lastSeenOffset = offset

        let streaks = streaks()
        let saved = Dictionary(dayResults().map { (calendar.savedDay($0.day), $0) }, uniquingKeysWith: { first, _ in first })
        if let first = streaks.map({ calendar.startOfDay(for: $0.createdAt) }).min() {
            var day = max(app.lastProcessedDay.map { self.day(after: calendar.savedDay($0)) } ?? first, first)
            while day <= yesterday {
                let result = rules.dayResult(streaks, day: day)
                saveResult(result.kind, missedAt: result.missedAt, on: day, existing: saved[day])
                day = self.day(after: day)
            }
        }
        app.lastProcessedDay = yesterday

        // Today so far: a miss that has happened, or a +1 that has been earned, is kept from now on.
        let todayRecord = rules.dayRecord(streaks, day: today, now: now)
        if let firstMiss = todayRecord.items.filter({ $0.isMissed(at: now) }).map(\.closes).min() {
            saveResult(.broken, missedAt: firstMiss, on: today, existing: saved[today])
        } else if todayRecord.isComplete {
            saveResult(.counted, missedAt: nil, on: today, existing: saved[today])
        }

        let state = dayStreakState(now: now, streaks: streaks)
        app.longestDayStreak = max(app.longestDayStreak, state.longest)
        app.bestFlameForm = max(app.bestFlameForm, state.bestForm.rawValue)
        save()
    }

    /// Saves a day's result, combined with what was already saved for it: a miss always wins, then a +1.
    private func saveResult(_ kind: DayResultKind, missedAt: Date?, on day: Date, existing: DayResultRecord?) {
        guard let existing else {
            context.insert(DayResultRecord(day: day, kind: kind, missedAt: missedAt))
            return
        }
        let old = DayResultKind(rawValue: existing.kind) ?? .rest
        if old == .broken || kind == .broken {
            existing.kind = DayResultKind.broken.rawValue
            existing.missedAt = [existing.missedAt, missedAt].compactMap { $0 }.min()
        } else if old != .counted {
            existing.kind = kind.rawValue
        }
    }

    /// Records the windows a time zone change jumped over, so they don't count as misses.
    private func recordWindowsSkipped(before: Date, beforeOffset: Int, now: Date, nowOffset: Int) {
        let skipped = rules.windowsSkippedByClockJump(streaks(), before: before, beforeOffset: beforeOffset, now: now,
                                                      nowOffset: nowOffset)
        for (streakID, day) in skipped {
            guard let record = record(streakID.uuidString), !record.skippedWindows.contains(where: { calendar.savedDay($0.day) == day })
            else { continue }
            let window = SkippedWindowRecord(day: day)
            context.insert(window)
            window.streak = record
        }
    }

    /// The day streak right now: saved day results, then today as it stands, merged with the app record.
    func dayStreakState(now: Date, streaks: [StreakData]? = nil) -> DayStreakState {
        let streaks = streaks ?? self.streaks()
        let today = calendar.startOfDay(for: now)
        var state = StreakRules.dayStreak(results: pastResults(before: today),
                                          today: rules.dayRecord(streaks, day: today, now: now),
                                          todaySoFar: todaySoFar(today), now: now)
        return merged(state: &state)
    }

    /// What's already saved about today, if anything.
    private func todaySoFar(_ today: Date) -> (kind: DayResultKind, missedAt: Date?)? {
        dayResults().first { calendar.savedDay($0.day) == today }
            .map { (DayResultKind(rawValue: $0.kind) ?? .rest, $0.missedAt) }
    }

    /// What checking `id` in at `now` would do to the day streak (celebration steps 2 and 3), without saving.
    func previewCheckIn(_ id: String, now: Date) -> DayStreakChange? {
        let today = calendar.startOfDay(for: now)
        let streaks = streaks()
        let record = rules.dayRecord(streaks, day: today, now: now)
        var before = StreakRules.dayStreak(results: pastResults(before: today), today: record,
                                           todaySoFar: todaySoFar(today), now: now)
        before = merged(state: &before)
        var after = record
        after.items = record.items.map { item in
            var item = item
            if item.taskID == id { item.outcome = .checkedIn(at: now) }
            return item
        }
        let events = DayStreakRules.apply(after, at: now, to: before).1
        return events.lazy.compactMap { if case .grew(let change) = $0 { change } else { nil } }.first
    }

    func markEndedScreenShown(forBreakOn day: Date) {
        appRecord.endedScreenShownForBreak = day
        save()
    }

    private func pastResults(before today: Date) -> [(day: Date, kind: DayResultKind, missedAt: Date?)] {
        dayResults()
            .map { (calendar.savedDay($0.day), DayResultKind(rawValue: $0.kind) ?? .rest, $0.missedAt) }
            .filter { $0.0 < today }
    }

    /// Adds what only the app record knows: records that survive deleted streaks, and whether the
    /// "streak ended" screen was shown.
    private func merged(state: inout DayStreakState) -> DayStreakState {
        let app = appRecord
        state.longest = max(state.longest, app.longestDayStreak)
        state.bestForm = max(state.bestForm, FlameForm(rawValue: app.bestFlameForm) ?? .ember)
        if let lastBreak = state.lastBreak {
            state.lastBreak?.screenShown = app.endedScreenShownForBreak.map(calendar.savedDay) == lastBreak.day
        }
        return state
    }

    // MARK: Helpers

    private func day(after day: Date, by days: Int = 1) -> Date {
        calendar.date(byAdding: .day, value: days, to: day) ?? day.addingTimeInterval(Double(days) * 86_400)
    }

    private func save() {
        do { try context.save() } catch { assertionFailure("Couldn't save: \(error)") }
    }

    // MARK: DEBUG tools

    #if DEBUG
    /// Adds a few realistic weeks of streaks, check-ins (with photos), skips, and one miss to the saved data,
    /// then works out every day again (Settings → Developer → Fill with sample data).
    func fillSampleData(now: Date) {
        var random = SeededRandom(seed: 7)
        let today = calendar.startOfDay(for: now)
        // `missesOne`: the streak misses one scheduled day, about a week and a half ago (its fourth-to-last).
        let plans: [(StreakDraft, daysAgo: Int, missesOne: Bool)] = [
            (StreakDraft(name: "Gym", days: [.monday, .tuesday, .thursday, .friday],
                         window: TimeWindow(start: TimeOfDay(18), end: TimeOfDay(20)), skips: 1,
                         color: .coral, icon: "dumbbell.fill"), 27, false),
            (StreakDraft(name: "Morning skincare", days: Set(Weekday.allCases),
                         window: TimeWindow(start: TimeOfDay(7), end: TimeOfDay(9)), skips: 1,
                         color: .pink, icon: "drop.fill"), 27, false),
            (StreakDraft(name: "Guitar", days: [.monday, .wednesday, .saturday],
                         window: TimeWindow(start: TimeOfDay(12), end: TimeOfDay(13)), skips: 1,
                         color: .purple, icon: "music.note"), 20, true),
            (StreakDraft(name: "Journal", days: [.monday, .tuesday, .wednesday, .thursday, .friday],
                         window: TimeWindow(start: TimeOfDay(21), end: TimeOfDay(22)), skips: 2,
                         color: .teal, icon: "pencil"), 13, false),
        ]
        for (draft, daysAgo, missesOne) in plans {
            let created = day(after: today, by: -daysAgo)
            let id = create(draft, now: created)
            guard let record = record(id) else { continue }
            let missDay = missesOne ? scheduledPastDays(record.data(calendar: calendar), from: created, now: now).dropLast(3).last : nil
            var day = created
            while day <= today {
                let data = record.data(calendar: calendar)
                if rules.isJudged(data, on: day), let version = rules.version(data, on: day) {
                    let (opens, closes) = rules.window(version.window, on: day)
                    let isMiss = day == missDay
                    if closes <= now, !isMiss {
                        let skipsLeft = rules.skipsLeft(data, now: closes.addingTimeInterval(-1))
                        if skipsLeft > 0, random.next(below: 100) < 12 {
                            let skip = SkipRecord(day: day, time: opens.addingTimeInterval(-3_600))
                            context.insert(skip)
                            skip.streak = record
                        } else {
                            let minutes = Double(random.next(below: max(1, Int(closes.timeIntervalSince(opens) / 60) - 5)))
                            let time = opens.addingTimeInterval(minutes * 60)
                            let fileName = (try? photos.save(Self.samplePhoto(draft, at: time))) ?? ""
                            addCheckIn(to: record, at: time, photoFileName: fileName)
                        }
                    }
                }
                day = self.day(after: day)
            }
        }
        // Work out every day again, now that there's history.
        try? context.delete(model: DayResultRecord.self)
        appRecord.lastProcessedDay = nil
        save()
        catchUp(now: now)
    }

    /// The streak's scheduled days from `from` whose windows have closed by `now`, oldest first.
    private func scheduledPastDays(_ streak: StreakData, from: Date, now: Date) -> [Date] {
        var days: [Date] = []
        var day = calendar.startOfDay(for: from)
        while day <= now {
            if rules.isJudged(streak, on: day), let version = rules.version(streak, on: day),
               rules.window(version.window, on: day).closes <= now {
                days.append(day)
            }
            day = self.day(after: day)
        }
        return days
    }

    /// A stand-in photo: the streak's color with its icon and the time (the simulator has no camera).
    static func samplePhoto(_ draft: StreakDraft? = nil, at time: Date = Date()) -> UIImage {
        let size = CGSize(width: 900, height: 1200)
        let color = UIColor(named: (draft?.color ?? .orange).assetName) ?? .orange
        return UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let configuration = UIImage.SymbolConfiguration(pointSize: 260, weight: .bold)
            if let symbol = UIImage(systemName: draft?.icon ?? "camera.fill", withConfiguration: configuration)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) {
                symbol.draw(at: CGPoint(x: (size.width - symbol.size.width) / 2, y: 380))
            }
            let text = (draft?.name ?? "Sample photo") + "\n" + Formatters.current.photoDate(time)
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            (text as NSString).draw(in: CGRect(x: 40, y: 800, width: size.width - 80, height: 300), withAttributes: [
                .font: UIFont.systemFont(ofSize: 64, weight: .heavy),
                .foregroundColor: UIColor.white,
                .paragraphStyle: style,
            ])
        }
    }
    #endif
}

#if DEBUG
/// Repeatable "random" numbers, so sample data looks the same every time.
struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next(below bound: Int) -> Int {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Int(z % UInt64(max(bound, 1)))
    }
}
#endif
