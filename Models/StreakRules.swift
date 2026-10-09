import Foundation

// The saved records as plain values (context.md §11), and every rule that turns them into what screens
// show: streaks, longest streaks, this week, skips left, history, and each day's result for the day streak.
// Nothing here touches storage, so it can all be tested directly.

/// One schedule version: the days, window, and skips that apply from `effectiveFrom` (midnight) on.
struct ScheduleData: Hashable {
    var weekdays: Set<Weekday>
    var window: TimeWindow
    var skipsPerWeek: Int
    var effectiveFrom: Date
}

struct CheckInData: Hashable {
    var id: UUID
    /// Midnight at the start of the day it counts for.
    var day: Date
    var time: Date
    var photoFileName: String
}

struct SkipData: Hashable {
    var id: UUID
    var day: Date
    var time: Date
    /// A later check-in that day gave it back.
    var refunded: Bool
}

/// One time the streak was archived, and when it came back (nil while still archived).
struct ArchivePeriod: Hashable {
    var archivedAt: Date
    var restoredAt: Date?
}

/// Everything saved about one streak.
struct StreakData: Hashable, Identifiable {
    var id: UUID
    var name: String
    var color: StreakColor
    var icon: String
    var createdAt: Date
    /// Every archive period, oldest first; the last one is open while it's archived.
    var archives: [ArchivePeriod] = []
    var versions: [ScheduleData]
    var checkIns: [CheckInData] = []
    var skips: [SkipData] = []

    var isArchived: Bool { archives.last.map { $0.restoredAt == nil } ?? false }
}

/// How one scheduled day went for one streak.
enum DayOutcome: Hashable {
    case checkedIn(at: Date)
    case skipped(at: Date)
    /// The window hasn't closed yet and nothing's done.
    case pending
    case missed
}

/// A finished day's result for the day streak (context.md §10–11).
enum DayResultKind: Int, Codable {
    case rest = 0, allSkipped = 1, counted = 2, broken = 3
}

/// Where a streak stands, worked out from its records.
struct StreakSummary: Hashable {
    var current: Streak
    var longest: Streak
    /// The latest time it ended, if nothing's been checked in since.
    var ended: (day: Date, at: Streak)?
    /// Every miss that ended a streak, and what the streak was then (for History).
    var endedByDay: [Date: Streak] = [:]

    static func == (lhs: StreakSummary, rhs: StreakSummary) -> Bool {
        lhs.current == rhs.current && lhs.longest == rhs.longest && lhs.ended?.day == rhs.ended?.day
            && lhs.ended?.at == rhs.ended?.at
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(current)
        hasher.combine(longest)
    }
}

struct StreakRules {
    var calendar: Calendar = .current

    // MARK: Schedule

    /// The version in effect on `day`: the latest one that started on or before it.
    func version(_ streak: StreakData, on day: Date) -> ScheduleData? {
        let start = calendar.startOfDay(for: day)
        return streak.versions
            .filter { $0.effectiveFrom <= start }
            .max { $0.effectiveFrom < $1.effectiveFrom }
            ?? streak.versions.min { $0.effectiveFrom < $1.effectiveFrom }
    }

    /// When the window opens and closes on `day` (local time).
    func window(_ window: TimeWindow, on day: Date) -> (opens: Date, closes: Date) {
        let start = calendar.startOfDay(for: day)
        func at(_ time: TimeOfDay) -> Date {
            calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: start) ?? start
        }
        return (at(window.start), at(window.end))
    }

    /// Whether `day` counts for this streak: a scheduled day (by the version in effect then), whose
    /// window opens after the streak was created, and that wasn't lost to archiving.
    /// - Archiving stops counting from that moment (a window still open then doesn't count).
    /// - After a restore, counting starts the next day.
    func isJudged(_ streak: StreakData, on day: Date) -> Bool {
        guard let version = version(streak, on: day), version.weekdays.contains(Weekday(day, calendar: calendar))
        else { return false }
        let (opens, closes) = window(version.window, on: day)
        if opens < streak.createdAt { return false }
        let dayStart = calendar.startOfDay(for: day)
        for period in streak.archives where period.archivedAt <= closes {
            guard let restored = period.restoredAt else { return false }
            if dayStart <= calendar.startOfDay(for: restored) { return false }
        }
        return true
    }

    /// How `day` went, or nil if it doesn't count for this streak.
    func outcome(_ streak: StreakData, on day: Date, now: Date) -> DayOutcome? {
        guard isJudged(streak, on: day), let version = version(streak, on: day) else { return nil }
        let start = calendar.startOfDay(for: day)
        if let checkIn = streak.checkIns.filter({ $0.day == start }).min(by: { $0.time < $1.time }) {
            return .checkedIn(at: checkIn.time)
        }
        if let skip = streak.skips.first(where: { $0.day == start && !$0.refunded }) {
            return .skipped(at: skip.time)
        }
        return window(version.window, on: day).closes <= now ? .missed : .pending
    }

    // MARK: Streaks

    /// The current and longest streak, walking every day from creation to today.
    /// Weeks: a Monday–Sunday week counts once it's over, if nothing in it was missed and at least one day
    /// was checked in; a streak's first partial week counts the same way (context.md §6).
    func summary(_ streak: StreakData, now: Date) -> StreakSummary {
        var weeks = 0, daysThisWeek = 0, total = 0
        var weekHasCheckIn = false
        var longest = Streak.zero
        var ended: (day: Date, at: Streak)?
        var endedByDay: [Date: Streak] = [:]
        var lastCheckIn: Date?
        var archivesPassed = 0

        let today = calendar.startOfDay(for: now)
        var day = calendar.startOfDay(for: streak.createdAt)
        func current() -> Streak { Streak(weeks: weeks, days: daysThisWeek, totalCheckIns: total) }
        func reset() { weeks = 0; daysThisWeek = 0; total = 0; weekHasCheckIn = false }

        while day <= today {
            if Weekday(day, calendar: calendar) == .monday, day > calendar.startOfDay(for: streak.createdAt) {
                if weekHasCheckIn { weeks += 1 }
                daysThisWeek = 0
                weekHasCheckIn = false
            }
            switch outcome(streak, on: day, now: now) {
            case .checkedIn(let time):
                total += 1
                daysThisWeek += 1
                weekHasCheckIn = true
                lastCheckIn = time
            case .missed:
                if total > 0 {
                    ended = (day, current())
                    endedByDay[day] = current()
                }
                reset()
            case .skipped, .pending, nil:
                break
            }
            // Also catches a week that just closed: the same check-ins, shown as "1w" instead of "0w 2d".
            if total > 0, total >= longest.totalCheckIns { longest = current() }
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86_400)
            // Archiving ends the streak (without a "streak ended" message), after that day's check-in counted.
            let archived = streak.archives.filter { $0.archivedAt < next }.count
            if archived > archivesPassed {
                archivesPassed = archived
                reset()
                ended = nil
            }
            day = next
        }

        if let end = ended, let lastCheckIn, lastCheckIn > end.day { ended = nil }
        let isArchived = streak.isArchived
        return StreakSummary(current: isArchived ? .zero : current(), longest: longest,
                             ended: isArchived ? nil : ended, endedByDay: endedByDay)
    }

    /// Skips left this week: the week's allowance (by today's version) minus skips used and not given back.
    func skipsLeft(_ streak: StreakData, now: Date) -> Int {
        guard let version = version(streak, on: now) else { return 0 }
        let monday = startOfWeek(now)
        let used = streak.skips.filter { !$0.refunded && $0.day >= monday && $0.day <= calendar.startOfDay(for: now) }
        return max(0, version.skipsPerWeek - used.count)
    }

    /// Midnight on the Monday of `date`'s week.
    func startOfWeek(_ date: Date) -> Date {
        let start = calendar.startOfDay(for: date)
        let back = Weekday(start, calendar: calendar).rawValue - 1
        return calendar.date(byAdding: .day, value: -back, to: start) ?? start
    }

    // MARK: Day streak

    /// The day streak's view of one day: every judged streak's item (archived ones count up to the moment
    /// they were archived).
    func dayRecord(_ streaks: [StreakData], day: Date, now: Date) -> DayRecord {
        let start = calendar.startOfDay(for: day)
        let items = streaks.compactMap { streak -> DayStreakItem? in
            guard let outcome = outcome(streak, on: start, now: now), let version = version(streak, on: start) else {
                return nil
            }
            let (opens, closes) = window(version.window, on: start)
            let itemOutcome: DayStreakItem.Outcome = switch outcome {
            case .checkedIn(let time): .checkedIn(at: time)
            case .skipped: .skipped
            case .pending, .missed: .pending
            }
            return DayStreakItem(taskID: streak.id.uuidString, taskName: streak.name, opens: opens, closes: closes,
                                 outcome: itemOutcome)
        }
        return DayRecord(day: start, items: items)
    }

    /// A finished day's result, and the time of its first miss.
    func dayResult(_ streaks: [StreakData], day: Date) -> (kind: DayResultKind, missedAt: Date?) {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        let record = dayRecord(streaks, day: start, now: end)
        if let firstMiss = record.items.filter({ $0.isMissed(at: end) }).map(\.closes).min() {
            return (.broken, firstMiss)
        }
        if record.items.isEmpty { return (.rest, nil) }
        return record.isComplete ? (.counted, nil) : (.allSkipped, nil)
    }

    /// The day streak folded from finished days' results (oldest first), then today as it stands.
    static func dayStreak(results: [(day: Date, kind: DayResultKind, missedAt: Date?)], today: DayRecord, now: Date)
        -> DayStreakState {
        var state = DayStreakState()
        for result in results.sorted(by: { $0.day < $1.day }) {
            switch result.kind {
            case .counted:
                state.current += 1
                state.longest = max(state.longest, state.current)
                state.bestForm = max(state.bestForm, state.form)
                state.lastCountedDay = result.day
            case .broken:
                if state.current > 0 {
                    state.lastBreak = .init(day: result.day, at: result.missedAt ?? result.day, length: state.current)
                }
                state.current = 0
                state.missedDay = result.day
            case .rest, .allSkipped:
                break
            }
        }
        return DayStreakRules.apply(today, at: now, to: state).0
    }

    // MARK: Snapshots for the screens

    /// Everything a screen shows about one streak at `now`.
    func snapshot(_ streak: StreakData, now: Date) -> TaskSnapshot {
        let today = calendar.startOfDay(for: now)
        let version = version(streak, on: today)
            ?? ScheduleData(weekdays: [], window: TimeWindow(start: TimeOfDay(9), end: TimeOfDay(10)), skipsPerWeek: 0,
                            effectiveFrom: today)
        let summary = summary(streak, now: now)
        let todayWeekday = Weekday(today, calendar: calendar)

        // Today
        let todayState: TodayState
        if !streak.isArchived, let outcome = outcome(streak, on: today, now: now) {
            let (opens, closes) = window(version.window, on: today)
            let phase: WindowPhase = now < opens ? .before : (now < closes ? .open : .after)
            let completion: Completion = switch outcome {
            case .checkedIn(let time): .done(at: TimeOfDay(time, calendar: calendar))
            case .skipped: .skipped
            case .pending, .missed: .none
            }
            todayState = .scheduled(phase, completion)
        } else {
            todayState = .notToday(next: nextDay(streak, after: today) ?? .tomorrow)
        }

        // This week's circles
        let monday = startOfWeek(now)
        var week: [WeekDayEntry] = []
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: monday) else { continue }
            let weekday = Weekday(day, calendar: calendar)
            if day > today {
                if !streak.isArchived, let future = self.version(streak, on: day), future.weekdays.contains(weekday) {
                    week.append(WeekDayEntry(day: weekday, status: .upcoming))
                }
                continue
            }
            guard let outcome = outcome(streak, on: day, now: now) else { continue }
            let status: WeekDayStatus = switch outcome {
            case .checkedIn: .done
            case .skipped: .skipped
            case .missed: .missed
            case .pending: .today
            }
            week.append(WeekDayEntry(day: weekday, status: status))
        }

        // Pending next-Monday change to days or skips
        let nextMonday = calendar.date(byAdding: .day, value: 7, to: monday) ?? monday
        let upcoming = self.version(streak, on: nextMonday)
        let nextWeek = upcoming.flatMap { next -> NextWeekChange? in
            next.weekdays == version.weekdays && next.skipsPerWeek == version.skipsPerWeek
                ? nil : NextWeekChange(days: next.weekdays.sorted(), skipsPerWeek: next.skipsPerWeek)
        }

        let checkIns = streak.checkIns.sorted { $0.time > $1.time }
        var snapshot = TaskSnapshot(
            id: streak.id.uuidString,
            name: streak.name,
            days: version.weekdays.sorted(),
            window: version.window,
            skipsPerWeek: version.skipsPerWeek,
            skipsLeft: skipsLeft(streak, now: now),
            streak: summary.current,
            longest: summary.longest,
            today: todayState,
            streakEnded: summary.ended.map { StreakEnded(on: Weekday($0.day, calendar: calendar), at: $0.at) },
            week: week,
            checkIns: checkIns.map(\.time),
            isArchived: streak.isArchived,
            color: streak.color,
            icon: streak.icon,
            createdAt: streak.createdAt)
        snapshot.photoFiles = Dictionary(checkIns.map { ($0.time, $0.photoFileName) }, uniquingKeysWith: { a, _ in a })
        snapshot.recordedEvents = pastEvents(streak, now: now, summary: summary)
        snapshot.nextWeek = nextWeek
        return snapshot
    }

    /// The next scheduled day after `day`, by the versions in effect then.
    func nextDay(_ streak: StreakData, after day: Date) -> NextDay? {
        for offset in 1...14 {
            guard let next = calendar.date(byAdding: .day, value: offset, to: day),
                  let version = version(streak, on: next) else { continue }
            let weekday = Weekday(next, calendar: calendar)
            if version.weekdays.contains(weekday) { return offset == 1 ? .tomorrow : .weekday(weekday) }
        }
        return nil
    }

    /// Skips and misses for History, newest first. Check-ins come from the photos.
    func pastEvents(_ streak: StreakData, now: Date, summary: StreakSummary? = nil) -> [HistoryEvent] {
        let ended = (summary ?? self.summary(streak, now: now)).endedByDay
        let id = streak.id.uuidString
        var events: [HistoryEvent] = []
        let today = calendar.startOfDay(for: now)
        var day = calendar.startOfDay(for: streak.createdAt)
        while day <= today {
            switch outcome(streak, on: day, now: now) {
            case .skipped(let time):
                events.append(HistoryEvent(taskID: id, taskName: streak.name, date: time, kind: .skip))
            case .missed:
                if let version = version(streak, on: day) {
                    events.append(HistoryEvent(taskID: id, taskName: streak.name,
                                               date: window(version.window, on: day).closes,
                                               kind: .miss(streakEnded: ended[day])))
                }
            case .checkedIn, .pending, nil:
                break
            }
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86_400)
        }
        return events.sorted { $0.date > $1.date }
    }
}
