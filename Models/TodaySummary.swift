import Foundation

/// What the today summary card shows (design.md §4.1): checked in out of scheduled, and what's next.
struct TodaySummary: Hashable {
    /// Tasks checked in today.
    var done: Int
    /// Tasks scheduled today.
    var total: Int
    var nextUp: NextUp?

    struct NextUp: Hashable {
        var taskName: String
        /// Nil means today.
        var day: NextDay?
        var start: TimeOfDay
        /// Its window is open right now.
        var isOpenNow = false
    }

    var isAllDone: Bool { total > 0 && done == total }
    /// Streaks exist, but none is scheduled today.
    var isRestDay: Bool { total == 0 }
    var progress: Double { total == 0 ? 0 : Double(done) / Double(total) }

    init(done: Int, total: Int, nextUp: NextUp?) {
        self.done = done
        self.total = total
        self.nextUp = nextUp
    }

    /// Builds the summary from the tasks as they stand at `now`.
    init(tasks: [TaskSnapshot], now: Date, calendar: Calendar = .current) {
        let scheduledToday = tasks.filter(\.isScheduledToday)
        total = scheduledToday.count
        done = scheduledToday.filter { if case .done = $0.cardState { true } else { false } }.count

        // Open right now and not done yet: that's what's next.
        if let open = scheduledToday.filter({ $0.cardState == .open }).min(by: { $0.window.start < $1.window.start }) {
            nextUp = NextUp(taskName: open.name, day: nil, start: open.window.start, isOpenNow: true)
            return
        }

        // Later today: windows that haven't opened yet.
        let laterToday = scheduledToday
            .filter { $0.cardState == .upcoming }
            .min { $0.window.start < $1.window.start }
        if let task = laterToday {
            nextUp = NextUp(taskName: task.name, day: nil, start: task.window.start)
            return
        }

        // Otherwise the soonest scheduled day after today, then the earliest window that day.
        let today = Weekday(now, calendar: calendar)
        let upcoming = tasks.compactMap { task -> (task: TaskSnapshot, days: Int)? in
            guard let next = task.days.map({ today.daysUntil($0) }).min() else { return nil }
            return (task, next)
        }
        let soonest = upcoming.min {
            ($0.days, $0.task.window.start.minutesSinceMidnight) < ($1.days, $1.task.window.start.minutesSinceMidnight)
        }
        nextUp = soonest.flatMap { item in
            item.task.nextDay(after: today).map { NextUp(taskName: item.task.name, day: $0, start: item.task.window.start) }
        }
    }
}
