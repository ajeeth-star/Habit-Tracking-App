import Foundation
import Testing
import UIKit
@testable import HabitApp

/// Streak colors and icons, the greeting, and the week strip. Sample "now" is Thursday,
/// October 1, 2026, 6:30 PM.
struct StreakStyleTests {
    let format = Formatters(locale: Locale(identifier: "en_US"), timeZone: TimeZone(identifier: "UTC")!)

    // MARK: Palette and icons

    @Test("Every streak icon is a real SF Symbol", arguments: StreakIcon.all)
    func iconExists(symbol: String) {
        #expect(UIImage(systemName: symbol) != nil)
    }

    @Test func twentyFourIcons() {
        #expect(StreakIcon.all.count == 24)
        #expect(Set(StreakIcon.all).count == 24)
    }

    @Test func newStreaksGetTheNextUnusedColor() {
        #expect(StreakColor.nextUnused(after: []) == .coral)
        #expect(StreakColor.nextUnused(after: [.coral, .orange]) == .yellow)
        #expect(StreakColor.nextUnused(after: [.orange]) == .coral)
        #expect(StreakColor.nextUnused(after: StreakColor.allCases) == .coral)
        // The sample's active streaks use everything except yellow (the new color).
        #expect(StreakColor.nextUnused(after: SampleData.allTasks.map(\.color)) == .yellow)
    }

    @Test("Icons guessed from the name", arguments: [
        ("Gym", "dumbbell.fill"), ("Lift weights", "dumbbell.fill"), ("Morning run", "figure.run"),
        ("Skincare", "drop.fill"), ("Wash face", "drop.fill"), ("Read 20 pages", "book.fill"),
        ("Guitar", "guitars.fill"), ("Do the dishes", "sparkles"), ("Clean room", "sparkles"),
        ("Sleep by 11", "bed.double.fill"), ("Meditation", "star.fill"), ("", "star.fill"),
    ])
    func iconGuess(name: String, icon: String) {
        #expect(StreakIcon.guess(for: name) == icon)
    }

    @Test func colorNames() {
        #expect(StreakColor.coral.accessibilityName == "Coral")
        #expect(StreakColor.coral.assetName == "streakCoral")
        #expect(StreakIcon.all.allSatisfy { Strings.StreakStyle.iconName($0) != "Icon" })
    }

    @Test func checkInResultCarriesTheStreakColor() {
        #expect(SampleData.gym.checkInResult(at: SampleData.today).color == .coral)
    }

    // MARK: Greeting

    @Test("Greeting by time of day", arguments: [
        (5, "Good morning"), (11, "Good morning"), (12, "Good afternoon"), (16, "Good afternoon"),
        (17, "Good evening"), (23, "Good evening"), (0, "Good evening"), (4, "Good evening"),
    ])
    func greeting(hour: Int, expected: String) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: hour, minute: 59))!
        #expect(format.greeting(date) == expected)
    }

    @Test func greetingWithName() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let evening = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 18))!
        #expect(format.greeting(evening, name: "Ajeeth") == "Good evening, Ajeeth")
        #expect(format.greeting(evening, name: "  Ajeeth  ") == "Good evening, Ajeeth")
        #expect(format.greeting(evening, name: "   ") == "Good evening")
        #expect(format.greeting(evening, name: nil) == "Good evening")
    }

    // MARK: Week strip

    @Test func weekStripDays() {
        let days = WeekProgress.days(for: SampleData.allTasksWithArchived, now: SampleData.today)
        #expect(days.map(\.weekday) == Weekday.allCases)
        let calendar = Calendar.current
        #expect(days.map { calendar.component(.day, from: $0.date) } == [28, 29, 30, 1, 2, 3, 4])

        // Monday and Tuesday: everything scheduled was checked in.
        #expect(days[0].kind == .past && days[0].isComplete)
        #expect(days[1].kind == .past && days[1].isComplete)
        // Wednesday: skincare and guitar done, journal skipped.
        #expect(days[2].done == 2 && days[2].total == 3 && !days[2].isComplete)
        // Thursday is today: the same numbers as the summary ring.
        #expect(days[3].kind == .today && days[3].done == 1 && days[3].total == 5)
        // Friday to Sunday haven't happened yet.
        #expect(days[4...].allSatisfy { $0.kind == .plain })
    }

    @Test func archivedStreaksAreLeftOut() {
        // Meditation (archived) has no entries this week, but check it's never counted.
        let withArchivedDone = SampleData.meditation
        var archived = withArchivedDone
        archived.week = [WeekDayEntry(day: .monday, status: .done)]
        let days = WeekProgress.days(for: [archived], now: SampleData.today)
        #expect(days[0].kind == .plain && days[0].total == 0)
    }

    @Test func weekStripVoiceOver() {
        let days = WeekProgress.days(for: SampleData.allTasks, now: SampleData.today)
        let local = Formatters(locale: Locale(identifier: "en_US"))
        #expect(local.weekStripLabel(days[0]) == "Monday, all done. Opens history.")
        #expect(local.weekStripLabel(days[2]) == "Wednesday, 2 of 3 done. Opens history.")
        #expect(local.weekStripLabel(days[3]) == "Thursday, today, 1 of 5 done")
        #expect(local.weekStripLabel(days[5]) == "Saturday")
        // A past day with nothing scheduled.
        let rest = WeekProgress.days(for: [SampleData.climbing], now: SampleData.today)
        #expect(local.weekStripLabel(rest[2]) == "Wednesday, nothing scheduled. Opens history.")
    }

    @Test func onlyPastDaysAreTappable() {
        let days = WeekProgress.days(for: SampleData.allTasks, now: SampleData.today)
        #expect(days.map(\.isPast) == [true, true, true, false, false, false, false])
    }
}
