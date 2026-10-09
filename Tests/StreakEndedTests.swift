import Foundation
import Testing
@testable import HabitApp

/// The two "streak ended" lines on a card (design.md §4.1). Sample today is Thursday.
struct StreakEndedTests {
    let format = Formatters(locale: Locale(identifier: "en_US"))
    let ended = Streak(weeks: 3, days: 3, totalCheckIns: 15)

    // MARK: Line 1

    @Test func endedToday() {
        #expect(format.streakEndedLine(StreakEnded(on: .thursday, at: ended), today: .thursday)
            == "Streak ended today at 3w 3d")
    }

    @Test func endedYesterday() {
        #expect(format.streakEndedLine(StreakEnded(on: .wednesday, at: ended), today: .thursday)
            == "Streak ended yesterday at 3w 3d")
        // Across the week boundary: Sunday is yesterday on a Monday.
        #expect(format.streakEndedLine(StreakEnded(on: .sunday, at: ended), today: .monday)
            == "Streak ended yesterday at 3w 3d")
    }

    @Test func endedEarlier() {
        #expect(format.streakEndedLine(StreakEnded(on: .monday, at: ended), today: .thursday)
            == "Streak ended Monday at 3w 3d")
    }

    // MARK: Line 2

    /// Guitar: Mon, Wed, Thu, Sat; missed today, so today's window has closed.
    @Test func windowClosedTodayPointsToTheNextTry() {
        #expect(format.longestLine(for: SampleData.guitar, today: .thursday) == "Longest: 5w 1d · Next try: Saturday")
    }

    @Test func nextTryTomorrow() {
        var task = SampleData.guitar
        task.days = [.thursday, .friday]
        #expect(format.longestLine(for: task, today: .thursday) == "Longest: 5w 1d · Next try: Tomorrow")
    }

    @Test func startsFreshWhileTodaysWindowIsStillAhead() {
        var task = SampleData.guitar
        task.today = .scheduled(.before, .none)
        #expect(format.longestLine(for: task, today: .thursday) == "Longest: 5w 1d · Starts fresh today")
        task.today = .scheduled(.open, .none)
        #expect(format.longestLine(for: task, today: .thursday) == "Longest: 5w 1d · Starts fresh today")
    }

    @Test func notScheduledTodayPointsToTheNextTry() {
        var task = SampleData.guitar
        task.today = .notToday(next: .weekday(.saturday))
        #expect(format.longestLine(for: task, today: .thursday) == "Longest: 5w 1d · Next try: Saturday")
    }
}
