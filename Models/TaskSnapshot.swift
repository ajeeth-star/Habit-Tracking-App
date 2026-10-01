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
        guard let todayIndex = week.firstIndex(where: { $0.status == .today }) else { return [] }
        return week[(todayIndex + 1)...].filter { $0.status == .upcoming }.map(\.day)
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

/// What the check-in success screen shows.
struct CheckInResult: Hashable {
    var taskName: String
    var streak: Streak
    /// Scheduled days still to do this week after this check-in.
    var remainingThisWeek: Int
    /// Skips left, when checking in gave back a skip used earlier today.
    var refundedSkipsLeft: Int?
}
