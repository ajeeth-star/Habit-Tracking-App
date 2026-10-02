import Foundation

/// A streak as the app displays it (context.md §6).
struct Streak: Hashable {
    /// Full Monday–Sunday weeks completed.
    var weeks: Int
    /// Check-ins so far in the current week.
    var days: Int
    /// Total check-ins in the streak, for the days-only display.
    var totalCheckIns: Int

    static let zero = Streak(weeks: 0, days: 0, totalCheckIns: 0)
}

/// How streaks are shown: "3w 2d" or "17 days".
enum StreakDisplayMode: String, CaseIterable {
    case weeksAndDays
    case daysOnly
}

