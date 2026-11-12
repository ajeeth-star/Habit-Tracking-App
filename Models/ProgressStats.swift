import Foundation

// The Progress tab (context.md §5, design.md §4.19): the month calendar, this month's stats, each streak's last
// 30 days, and the best weekday. Everything is calculated from the snapshots' day marks; nothing is saved.

/// One day in the Progress calendar.
struct ProgressDay: Hashable, Identifiable {
    enum Kind: Hashable {
        /// Everything scheduled was checked in or skipped, with at least one check-in.
        case full
        /// Something scheduled, nothing missed, but not full: today in progress, or everything skipped.
        case partial
        /// A window closed with no check-in and no skip.
        case missed
        /// Nothing scheduled (a rest day, or before any streak existed).
        case rest
        /// Still to come.
        case future
    }

    var date: Date
    var kind: Kind
    var isToday: Bool
    /// Streaks checked in that day, and streaks that counted that day.
    var done: Int
    var total: Int
    /// A past day from the first streak's day on: tapping it opens History at that day.
    var opensHistory: Bool

    var id: Date { date }
    var progress: Double { total == 0 ? 0 : Double(done) / Double(total) }
}

/// The four "This month" numbers.
struct MonthStats: Hashable {
    var checkIns = 0
    /// Check-ins ÷ windows that have finished or been resolved; nil with nothing to count.
    var completionRate: Double?
    var perfectDays = 0
    var longestDayStreak = 0
}

/// One month of the Progress tab.
struct ProgressMonth: Hashable {
    /// Midnight on the 1st.
    var start: Date
    /// Empty cells before the 1st, so the grid starts on Monday.
    var leadingBlanks: Int
    var days: [ProgressDay]
    var stats: MonthStats
}

/// The weekday with the best completion rate.
struct BestDay: Hashable {
    var weekday: Weekday
    var rate: Double
}

/// How much was done on one day, across every streak.
private struct DayTally {
    var done = 0, skipped = 0, missed = 0, pending = 0

    var total: Int { done + skipped + missed + pending }
    /// Resolved one way or another (today's windows still to come don't count).
    var resolved: Int { done + skipped + missed }

    mutating func add(_ mark: DayMark) {
        switch mark {
        case .done: done += 1
        case .skipped: skipped += 1
        case .missed: missed += 1
        case .pending: pending += 1
        }
    }
}

struct ProgressStats {
    /// Days of history needed before the best day shows.
    static let bestDayMinimumDays = 14
    /// The "Your streaks" rows look back this many days, today included.
    static let recentDays = 30

    let tasks: [TaskSnapshot]
    let now: Date
    let calendar: Calendar
    /// Every streak's marks (archived ones too: their past days still count).
    private let marks: [(task: TaskSnapshot, days: [Date: DayMark])]
    private let tallies: [Date: DayTally]
    private let today: Date

    init(tasks: [TaskSnapshot], now: Date, calendar: Calendar = .current) {
        self.tasks = tasks
        self.now = now
        self.calendar = calendar
        today = calendar.startOfDay(for: now)
        marks = tasks.map { ($0, $0.progressDays(now: now, calendar: calendar)) }
        var tallies: [Date: DayTally] = [:]
        for (_, days) in marks {
            for (day, mark) in days { tallies[day, default: DayTally()].add(mark) }
        }
        self.tallies = tallies
    }

    var isEmpty: Bool { tasks.isEmpty }

    /// The day the first streak was created (or its earliest counted day).
    var firstDay: Date? {
        let created = tasks.compactMap(\.createdAt).map { calendar.startOfDay(for: $0) }
        return (created + tallies.keys).min()
    }

    /// Midnight on the 1st of `date`'s month.
    func startOfMonth(_ date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    /// The months that can be shown: from the first streak's month to this month.
    var monthRange: ClosedRange<Date> {
        let current = startOfMonth(now)
        return min(firstDay.map(startOfMonth) ?? current, current)...current
    }

    /// The month `offset` months from this one (0 is this month, -1 last month), kept within `monthRange`.
    func month(offset: Int) -> ProgressMonth {
        let range = monthRange
        let start = calendar.date(byAdding: .month, value: offset, to: range.upperBound) ?? range.upperBound
        return month(starting: min(max(start, range.lowerBound), range.upperBound))
    }

    func month(starting start: Date) -> ProgressMonth {
        let count = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
        let first = firstDay
        let days = (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }.map { date in
            day(date, firstDay: first)
        }
        return ProgressMonth(start: start, leadingBlanks: Weekday(start, calendar: calendar).rawValue - 1,
                             days: days, stats: stats(for: days))
    }

    private func day(_ date: Date, firstDay: Date?) -> ProgressDay {
        let tally = tallies[date] ?? DayTally()
        let isToday = date == today
        let kind: ProgressDay.Kind
        if date > today {
            kind = .future
        } else if tally.total == 0 {
            kind = .rest
        } else if tally.missed > 0 {
            kind = .missed
        } else if tally.done > 0, tally.done + tally.skipped == tally.total {
            kind = .full
        } else {
            kind = .partial
        }
        let opensHistory = date < today && firstDay.map { date >= $0 } == true
        return ProgressDay(date: date, kind: kind, isToday: isToday, done: tally.done,
                           total: date > today ? 0 : tally.total, opensHistory: opensHistory)
    }

    /// Only days up to today count. The longest day streak follows the day streak's rules within the month: a full
    /// day adds one, a miss ends the run, rest and all-skipped days keep it going (context.md §10).
    private func stats(for days: [ProgressDay]) -> MonthStats {
        var stats = MonthStats()
        var done = 0, resolved = 0, run = 0
        for day in days where day.date <= today {
            let tally = tallies[day.date] ?? DayTally()
            done += tally.done
            resolved += tally.resolved
            switch day.kind {
            case .full:
                stats.perfectDays += 1
                run += 1
                stats.longestDayStreak = max(stats.longestDayStreak, run)
            case .missed:
                run = 0
            case .partial, .rest, .future:
                break
            }
        }
        stats.checkIns = done
        stats.completionRate = resolved == 0 ? nil : Double(done) / Double(resolved)
        return stats
    }

    /// Each active streak's completion rate over the last 30 days, in the Streaks tab's order.
    func recentRates(order: [TaskSnapshot]) -> [(task: TaskSnapshot, rate: Double?)] {
        let from = calendar.date(byAdding: .day, value: -(Self.recentDays - 1), to: today) ?? today
        return order.filter { !$0.isArchived }.map { task in
            let days = marks.first { $0.task.id == task.id }?.days ?? [:]
            var tally = DayTally()
            for (day, mark) in days where day >= from && day <= today { tally.add(mark) }
            return (task, tally.resolved == 0 ? nil : Double(tally.done) / Double(tally.resolved))
        }
    }

    /// The weekday with the highest completion rate across all history (ties go to the earlier weekday), once the
    /// first streak is at least two weeks old.
    var bestDay: BestDay? {
        guard let firstDay,
              let ready = calendar.date(byAdding: .day, value: Self.bestDayMinimumDays, to: firstDay),
              ready <= today else { return nil }
        var byWeekday: [Weekday: DayTally] = [:]
        for (day, tally) in tallies where day <= today {
            let weekday = Weekday(day, calendar: calendar)
            byWeekday[weekday, default: DayTally()].done += tally.done
            byWeekday[weekday, default: DayTally()].skipped += tally.skipped
            byWeekday[weekday, default: DayTally()].missed += tally.missed
        }
        var best: BestDay?
        for weekday in Weekday.allCases {
            guard let tally = byWeekday[weekday], tally.resolved > 0 else { continue }
            let rate = Double(tally.done) / Double(tally.resolved)
            if best.map({ rate > $0.rate }) ?? true { best = BestDay(weekday: weekday, rate: rate) }
        }
        return best
    }
}

extension TaskSnapshot {
    /// How each counted day went. Saved data has the real marks; sample data (the Design Gallery) makes do with its
    /// check-ins, this week's circles, and, between its first and last check-in, a skip on any scheduled day
    /// without one.
    func progressDays(now: Date, calendar: Calendar = .current) -> [Date: DayMark] {
        if let recordedDays { return recordedDays }
        let today = calendar.startOfDay(for: now)
        var marks: [Date: DayMark] = [:]
        let checkInDays = checkIns.map { calendar.startOfDay(for: $0) }
        if let first = checkInDays.min(), let last = checkInDays.max() {
            let weekdays = Set(days)
            var day = first
            while day <= last {
                if weekdays.contains(Weekday(day, calendar: calendar)) { marks[day] = .skipped }
                day = calendar.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86_400)
            }
        }
        for day in checkInDays { marks[day] = .done }
        let todayWeekday = Weekday(today, calendar: calendar)
        for entry in week {
            guard let date = calendar.date(byAdding: .day, value: entry.day.rawValue - todayWeekday.rawValue,
                                           to: today), date <= today else { continue }
            switch entry.status {
            case .done: marks[date] = .done
            case .skipped: marks[date] = .skipped
            case .missed: marks[date] = .missed
            case .today: marks[date] = .pending
            case .upcoming: break
            }
        }
        return marks
    }
}
