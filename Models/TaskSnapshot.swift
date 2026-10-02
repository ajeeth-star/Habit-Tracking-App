import Foundation

/// Everything a screen needs to draw one task, as it stands right now.
/// For this phase these come from `SampleData`; a later phase builds them from saved data.
struct TaskSnapshot: Identifiable, Hashable {
    let id: String
    var name: String
    /// Scheduled days, Monday first.
    var days: [Weekday]
    var window: TimeWindow
    var skipsPerWeek: Int
    var skipsLeft: Int
    var streak: Streak
    var longest: Streak
    var today: TodayState
    /// Set when the streak has broken and the "Streak ended" lines should show.
    var streakEnded: StreakEnded?
    /// This week's scheduled days and how each went.
    var week: [WeekDayEntry]
    /// Check-in photo times, newest first.
    var checkIns: [Date]
    /// Archived habits leave Today, stop reminding, and keep their photos and best streak.
    var isArchived = false
}

/// Where a task stands today.
enum TodayState: Hashable {
    case scheduled(WindowPhase, Completion)
    case notToday(next: NextDay)
}

/// Where the current time is relative to today's window.
enum WindowPhase: Hashable {
    case before, open, after
}

/// What has been done about today.
enum Completion: Hashable {
    case none
    case done(at: TimeOfDay)
    case skipped
}

/// When a task that isn't scheduled today is next due.
enum NextDay: Hashable {
    case tomorrow
    case weekday(Weekday)
}

struct StreakEnded: Hashable {
    /// The day the streak broke.
    var on: Weekday
    /// What the streak was when it broke.
    var at: Streak
}

struct WeekDayEntry: Hashable, Identifiable {
    var day: Weekday
    var status: WeekDayStatus

    var id: Weekday { day }
}

enum WeekDayStatus: Hashable {
    case done, skipped, missed, today, upcoming
}

/// The status a home-screen card shows.
enum TaskCardState: Hashable {
    case open, done(at: TimeOfDay), upcoming, skipped, missed, notToday(next: NextDay)
}

extension TaskSnapshot {
    var cardState: TaskCardState {
        switch today {
        case .notToday(let next): .notToday(next: next)
        case .scheduled(_, .done(let time)): .done(at: time)
        case .scheduled(_, .skipped): .skipped
        case .scheduled(.before, .none): .upcoming
        case .scheduled(.open, .none): .open
        case .scheduled(.after, .none): .missed
        }
    }

    var isScheduledToday: Bool {
        if case .scheduled = today { true } else { false }
    }

    /// Scheduled days later this week that haven't happened yet.
    var scheduledDaysAfterToday: [Weekday] {
        // Days up to and including today have a result (or the "today" ring); later days are upcoming.
        guard let todayIndex = week.lastIndex(where: { $0.status != .upcoming }) else { return week.map(\.day) }
        return week[(todayIndex + 1)...].map(\.day)
    }
}

/// What the skip confirmation dialog needs to say.
struct SkipPrompt: Hashable {
    var taskName: String
    /// Skips left before using this one.
    var skipsLeft: Int
    /// Scheduled days left this week, not counting today.
    var daysAfterToday: [Weekday]

    var isLastSkip: Bool { skipsLeft == 1 }
    /// Scheduled days left this week, including today.
    var daysLeftIncludingToday: Int { daysAfterToday.count + 1 }
}

extension TaskSnapshot {
    var skipPrompt: SkipPrompt {
        SkipPrompt(taskName: name, skipsLeft: skipsLeft, daysAfterToday: scheduledDaysAfterToday)
    }
}

/// What the streak celebration shows.
struct CheckInResult: Hashable {
    var taskName: String
    /// The streak in days before this check-in, for the count-up.
    var previousStreakDays: Int
    var streak: Streak
    /// Scheduled days still to do this week after this check-in.
    var remainingThisWeek: Int
    /// Skips left, when checking in gave back a skip used earlier today.
    var refundedSkipsLeft: Int?
}

extension TaskSnapshot {
    /// The next scheduled day after `today`: "Tomorrow" or a weekday. Nil if the task has no days.
    func nextDay(after today: Weekday) -> NextDay? {
        guard let next = days.min(by: { today.daysUntil($0) < today.daysUntil($1) }) else { return nil }
        return today.daysUntil(next) == 1 ? .tomorrow : .weekday(next)
    }

    /// Minutes from `now` until today's window closes, rounded up (0 once it has closed).
    func minutesUntilClose(from now: Date, calendar: Calendar = .current) -> Int {
        guard let close = calendar.date(bySettingHour: window.end.hour, minute: window.end.minute,
                                        second: 0, of: now) else { return 0 }
        return max(0, Int((close.timeIntervalSince(now) / 60).rounded(.up)))
    }

    /// This task as it looks right after checking in at `date`.
    /// Placeholder rules until the streaks phase: the streak gains a day, a skip used today comes back,
    /// and today's week circle turns done. Nothing is saved.
    func checkedIn(at date: Date) -> TaskSnapshot {
        var task = self
        guard case .scheduled(let phase, let completion) = today else { return task }
        if case .done = completion { return task }
        task.today = .scheduled(phase, .done(at: TimeOfDay(date)))
        task.streak.days += 1
        task.streak.totalCheckIns += 1
        if completion == .skipped { task.skipsLeft += 1 }
        task.streakEnded = nil
        // Today is the last day that isn't upcoming (see `scheduledDaysAfterToday`).
        if let todayIndex = week.lastIndex(where: { $0.status != .upcoming }) {
            task.week[todayIndex].status = .done
        }
        task.checkIns.insert(date, at: 0)
        return task
    }

    /// What the celebration shows after checking this task in at `date`.
    func checkInResult(at date: Date) -> CheckInResult {
        let after = checkedIn(at: date)
        return CheckInResult(
            taskName: name,
            previousStreakDays: streak.totalCheckIns,
            streak: after.streak,
            remainingThisWeek: scheduledDaysAfterToday.count,
            refundedSkipsLeft: today == .scheduled(.open, .skipped) ? after.skipsLeft : nil)
    }
}

extension TaskSnapshot {
    /// The next window strictly after today: how many days ahead (1…7) and when it starts.
    func nextWindow(after today: Weekday) -> (daysAhead: Int, start: TimeOfDay)? {
        guard let days = days.map({ today.daysUntil($0) }).min() else { return nil }
        return (days, window.start)
    }

    /// The best streak so far, counting the current one.
    var best: Streak {
        streak.totalCheckIns > longest.totalCheckIns ? streak : longest
    }

    /// Archived: the current streak ends, the best streak and photos are kept, and it leaves Today.
    func archived() -> TaskSnapshot {
        var task = self
        task.longest = best
        task.streak = .zero
        task.streakEnded = nil
        task.isArchived = true
        return task
    }

    /// Restored: a fresh streak starting from the next scheduled day after `weekday` (today); the best streak is kept.
    func restored(on weekday: Weekday) -> TaskSnapshot {
        var task = self
        task.isArchived = false
        task.streak = .zero
        task.streakEnded = nil
        task.skipsLeft = skipsPerWeek
        task.today = .notToday(next: nextDay(after: weekday) ?? .tomorrow)
        // This week only shows the scheduled days still to come.
        task.week = days.filter { $0 > weekday }.map { WeekDayEntry(day: $0, status: .upcoming) }
        return task
    }
}
