import Foundation

/// One day in the Today tab's week strip (design.md §4.1).
struct WeekStripDay: Hashable, Identifiable {
    enum Kind: Hashable {
        /// Already happened, with something scheduled.
        case past
        case today
        /// Still to come, or nothing was scheduled: just the number.
        case plain
    }

    var weekday: Weekday
    var date: Date
    var kind: Kind
    /// Streaks checked in that day.
    var done: Int
    /// Streaks scheduled that day.
    var total: Int

    var id: Weekday { weekday }
    var progress: Double { total == 0 ? 0 : Double(done) / Double(total) }
    var isComplete: Bool { total > 0 && done == total }
}

/// Builds the Monday–Sunday strip for the week containing `now`.
/// Past days come from each streak's "This week" circles (done counts; skips and misses don't);
/// today comes from today's state, the same numbers as the summary ring. Archived streaks are left out.
enum WeekProgress {
    static func days(for tasks: [TaskSnapshot], now: Date, calendar: Calendar = .current) -> [WeekStripDay] {
        let active = tasks.filter { !$0.isArchived }
        let today = Weekday(now, calendar: calendar)
        let startOfToday = calendar.startOfDay(for: now)
        let summary = TodaySummary(tasks: active, now: now, calendar: calendar)

        return Weekday.allCases.map { weekday in
            let offset = weekday.rawValue - today.rawValue
            let date = calendar.date(byAdding: .day, value: offset, to: startOfToday) ?? startOfToday

            if weekday == today {
                return WeekStripDay(weekday: weekday, date: date, kind: .today,
                                    done: summary.done, total: summary.total)
            }
            guard weekday < today else {
                return WeekStripDay(weekday: weekday, date: date, kind: .plain, done: 0, total: 0)
            }
            let entries = active.compactMap { $0.week.first { $0.day == weekday } }
            let done = entries.filter { $0.status == .done }.count
            return WeekStripDay(weekday: weekday, date: date, kind: entries.isEmpty ? .plain : .past,
                                done: done, total: entries.count)
        }
    }
}
