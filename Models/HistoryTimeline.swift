import Foundation

/// One line on the History tab: a check-in photo, a skip, or a miss.
struct HistoryEvent: Identifiable, Hashable {
    enum Kind: Hashable {
        case checkIn
        case skip
        /// The streak that ended, if one did.
        case miss(streakEnded: Streak?)
    }

    var taskID: String
    var taskName: String
    var date: Date
    var kind: Kind

    var id: String { "\(taskID)-\(date.timeIntervalSinceReferenceDate)-\(kind)" }
}

/// Builds the History tab's timeline (design.md §4.12) from the tasks.
/// Check-ins come from each task's photos. Skips and misses come from the saved records
/// (`recordedEvents`); for the gallery's sample data, which has none, from this week's circles.
enum HistoryTimeline {
    struct Day: Hashable {
        var date: Date
        var events: [HistoryEvent]
    }

    static func events(for tasks: [TaskSnapshot], now: Date, calendar: Calendar = .current) -> [HistoryEvent] {
        let today = calendar.startOfDay(for: now)
        let todayWeekday = Weekday(now, calendar: calendar)
        var events: [HistoryEvent] = []

        for task in tasks {
            events += task.checkIns.map {
                HistoryEvent(taskID: task.id, taskName: task.name, date: $0, kind: .checkIn)
            }
            if let recorded = task.recordedEvents {
                events += recorded
                continue
            }
            for entry in task.week where entry.status == .skipped || entry.status == .missed {
                // Days this week: today minus how far back the day is.
                let back = (todayWeekday.rawValue - entry.day.rawValue + 7) % 7
                guard let day = calendar.date(byAdding: .day, value: -back, to: today) else { continue }
                if entry.status == .skipped {
                    let at = calendar.date(bySettingHour: task.window.start.hour, minute: task.window.start.minute,
                                           second: 0, of: day) ?? day
                    events.append(HistoryEvent(taskID: task.id, taskName: task.name, date: at, kind: .skip))
                } else {
                    let at = calendar.date(bySettingHour: task.window.end.hour, minute: task.window.end.minute,
                                           second: 0, of: day) ?? day
                    let ended = task.streakEnded.flatMap { $0.on == entry.day ? $0.at : nil }
                    events.append(HistoryEvent(taskID: task.id, taskName: task.name, date: at,
                                               kind: .miss(streakEnded: ended)))
                }
            }
        }
        return events.sorted { $0.date > $1.date }
    }

    /// Events grouped by calendar day, newest day first, newest event first within a day.
    static func days(for tasks: [TaskSnapshot], now: Date, calendar: Calendar = .current) -> [Day] {
        var days: [Day] = []
        for event in events(for: tasks, now: now, calendar: calendar) {
            let day = calendar.startOfDay(for: event.date)
            if days.last?.date == day {
                days[days.count - 1].events.append(event)
            } else {
                days.append(Day(date: day, events: [event]))
            }
        }
        return days
    }
}
