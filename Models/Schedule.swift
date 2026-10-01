import Foundation

/// A day of the week. Weeks start on Monday (context.md §3), so Monday is first.
enum Weekday: Int, CaseIterable, Comparable, Hashable, Identifiable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: Int { rawValue }

    /// The matching `Calendar` weekday number (1 = Sunday … 7 = Saturday).
    var calendarWeekday: Int { rawValue % 7 + 1 }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// A clock time without a date, e.g. 6:00 PM.
struct TimeOfDay: Comparable, Hashable {
    var hour: Int
    var minute: Int

    init(_ hour: Int, _ minute: Int = 0) {
        self.hour = hour
        self.minute = minute
    }

    var minutesSinceMidnight: Int { hour * 60 + minute }

    static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool {
        lhs.minutesSinceMidnight < rhs.minutesSinceMidnight
    }
}

/// A task's daily check-in window, e.g. 6:00 – 8:00 PM.
struct TimeWindow: Hashable {
    var start: TimeOfDay
    var end: TimeOfDay

    /// Windows must end after they start; crossing midnight isn't allowed (design.md §4.3, open).
    var isValid: Bool { end > start }
}
