import Foundation

/// Today's timeline (design.md §4.1): every streak scheduled today except the open one(s) on hero cards, in
/// window-start order, and where the "now" marker falls between them.
struct TodayTimeline: Equatable {
    var tasks: [TaskSnapshot]
    /// How many tasks come before the "now" marker: those whose window starts at or before now.
    var nowIndex: Int

    /// `tasks` in their usual order (ties in start time keep it).
    init(tasks: [TaskSnapshot], now: Date, calendar: Calendar = .current) {
        let scheduled = tasks.filter { !$0.isArchived && $0.isScheduledToday && $0.cardState != .open }
        self.tasks = scheduled.enumerated()
            .sorted { ($0.element.window.start, $0.offset) < ($1.element.window.start, $1.offset) }
            .map(\.element)
        let current = TimeOfDay(now, calendar: calendar)
        nowIndex = self.tasks.filter { $0.window.start <= current }.count
    }

    var isEmpty: Bool { tasks.isEmpty }
}

/// The dot a timeline row shows on the line.
enum TimelineDot: Hashable {
    case done, upcoming, missed, skipped

    init(_ state: TaskCardState) {
        switch state {
        case .done: self = .done
        case .skipped: self = .skipped
        case .missed: self = .missed
        case .open, .upcoming, .notToday: self = .upcoming
        }
    }

    /// Done and skipped streaks are drawn faded in their slot.
    var isFaded: Bool { self == .done || self == .skipped }
}
