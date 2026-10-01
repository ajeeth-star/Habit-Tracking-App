import Foundation
import Testing
@testable import HabitApp

/// The in-memory rules behind the new Home: next scheduled day, the countdown, what a check-in
/// changes, and the today summary. Sample "now" is Thursday, October 1, 2026, 6:30 PM.
struct HomeModelTests {
    let now = SampleData.today

    @Test func weekdayFromDate() {
        #expect(Weekday(now) == .thursday)
        #expect(Weekday(now.addingTimeInterval(3 * 86_400)) == .sunday)
        #expect(Weekday(now.addingTimeInterval(4 * 86_400)) == .monday)
    }

    @Test func daysUntil() {
        #expect(Weekday.thursday.daysUntil(.friday) == 1)
        #expect(Weekday.thursday.daysUntil(.monday) == 4)
        #expect(Weekday.thursday.daysUntil(.thursday) == 7)
    }

    @Test func nextDayAfterToday() {
        #expect(SampleData.gym.nextDay(after: .thursday) == .tomorrow)              // Friday
        #expect(SampleData.guitar.nextDay(after: .thursday) == .weekday(.saturday))
        #expect(SampleData.walk.nextDay(after: .thursday) == .weekday(.sunday))
        #expect(SampleData.gym.nextDay(after: .friday) == .weekday(.monday))
    }

    @Test func minutesUntilClose() {
        #expect(SampleData.gym.minutesUntilClose(from: now) == 90)                  // 6:30 → 8:00
        #expect(SampleData.gym.minutesUntilClose(from: SampleData.closingSoon) == 12)
        #expect(SampleData.gym.minutesUntilClose(from: now.addingTimeInterval(30)) == 90) // rounds up
        #expect(SampleData.gym.minutesUntilClose(from: SampleData.time(21, 0)) == 0)
    }

    @Test func checkingInClosesTheTask() {
        let after = SampleData.gym.checkedIn(at: SampleData.time(18, 42))
        #expect(after.cardState == .done(at: TimeOfDay(18, 42)))
        #expect(after.streak.totalCheckIns == SampleData.gym.streak.totalCheckIns + 1)
        #expect(after.streak.days == SampleData.gym.streak.days + 1)
        #expect(after.week.first { $0.day == .thursday }?.status == .done)
        #expect(after.checkIns.count == SampleData.gym.checkIns.count + 1)
        #expect(after.skipsLeft == SampleData.gym.skipsLeft)
    }

    @Test func cantCheckInTwice() {
        let once = SampleData.gym.checkedIn(at: SampleData.time(18, 42))
        let twice = once.checkedIn(at: SampleData.time(19, 0))
        #expect(twice == once)
    }

    @Test func checkingInAfterASkipGivesItBack() {
        let after = SampleData.run.checkedIn(at: now)
        #expect(after.skipsLeft == SampleData.run.skipsLeft + 1)
        #expect(after.week.first { $0.day == .thursday }?.status == .done)
        let result = SampleData.run.checkInResult(at: now)
        #expect(result.refundedSkipsLeft == 1)
        #expect(result.remainingThisWeek == 1) // Saturday
    }

    @Test func celebrationResult() {
        let result = SampleData.gym.checkInResult(at: now)
        #expect(result.taskName == "Gym")
        #expect(result.previousStreakDays == 14)
        #expect(result.streak.totalCheckIns == 15)
        #expect(result.remainingThisWeek == 1) // Friday
        #expect(result.refundedSkipsLeft == nil)
    }

    @Test func summaryInProgress() {
        let summary = TodaySummary(tasks: SampleData.allTasks, now: now)
        #expect(summary.total == 5)   // skincare, guitar, run, gym, journal
        #expect(summary.done == 1)    // skincare
        #expect(!summary.isAllDone)
        // Gym is open (the hero shows it), so next up is Journal later today.
        #expect(summary.nextUp == .init(taskName: "Journal", day: nil, start: TimeOfDay(21)))
    }

    @Test func summaryAllDone() {
        let summary = TodaySummary(tasks: SampleData.allDoneTasks, now: now)
        #expect(summary.isAllDone)
        #expect(summary.progress == 1)
        // Earliest window tomorrow: Morning skincare at 7 AM.
        #expect(summary.nextUp == .init(taskName: "Morning skincare", day: .tomorrow, start: TimeOfDay(7)))
    }

    @Test func summaryWithNothingToday() {
        let summary = TodaySummary(tasks: [SampleData.climbing, SampleData.walk], now: now)
        #expect(summary.total == 0)
        #expect(summary.nextUp == .init(taskName: "Climbing", day: .tomorrow, start: TimeOfDay(20)))
    }
}
