import Foundation
import Testing
@testable import HabitApp

/// The text rules in design.md §3. Uses US English so results don't depend on the Mac's settings.
struct FormattersTests {
    let format = Formatters(locale: Locale(identifier: "en_US"), timeZone: TimeZone(identifier: "UTC")!)

    /// Apple's formatters use thin and narrow no-break spaces ("6:00\u{2009}–\u{2009}8:00\u{202F}PM").
    /// They look like normal spaces, so compare them as normal spaces.
    private func plain(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{2009}", with: " ")
            .replacingOccurrences(of: "\u{202F}", with: " ")
    }

    private func streak(_ weeks: Int, _ days: Int, total: Int = 0) -> Streak {
        Streak(weeks: weeks, days: days, totalCheckIns: total)
    }

    // MARK: Streaks

    @Test("Streak, long style", arguments: [
        (3, 2, "3 weeks 2 days"),
        (1, 1, "1 week 1 day"),
        (0, 2, "2 days"),
        (3, 0, "3 weeks"),
        (0, 0, "No streak yet"),
        (1, 0, "1 week"),
        (0, 1, "1 day"),
    ])
    func streakLong(weeks: Int, days: Int, expected: String) {
        #expect(format.streakLong(streak(weeks, days)) == expected)
    }

    @Test("Streak, short style", arguments: [
        (3, 2, "3w 2d"),
        (1, 1, "1w 1d"),
        (0, 2, "2d"),
        (3, 0, "3w"),
        (0, 0, "—"),
    ])
    func streakShort(weeks: Int, days: Int, expected: String) {
        #expect(format.streakShort(streak(weeks, days)) == expected)
    }

    @Test("Streak, days-only mode", arguments: [
        (14, "14 days"),
        (1, "1 day"),
        (0, "No streak yet"),
    ])
    func streakDaysOnly(total: Int, expected: String) {
        #expect(format.streakDaysOnly(streak(2, 0, total: total)) == expected)
    }

    @Test func streakFollowsToggle() {
        let s = streak(3, 2, total: 17)
        #expect(format.streakCompact(s, mode: .weeksAndDays) == "3w 2d")
        #expect(format.streakCompact(s, mode: .daysOnly) == "17 days")
        #expect(format.streakFull(s, mode: .weeksAndDays) == "3 weeks 2 days")
        #expect(format.streakFull(s, mode: .daysOnly) == "17 days")
    }

    // MARK: Skip counts

    @Test("Skips left", arguments: [
        (1, "1 skip left"),
        (2, "2 skips left"),
        (0, "No skips left"),
    ])
    func skipsLeft(count: Int, expected: String) {
        #expect(format.skipsLeft(count) == expected)
    }

    @Test func skipsOfTotal() {
        #expect(format.skipsOfTotal(left: 1, total: 1) == "1 of 1")
        #expect(format.skipsOfTotal(left: 0, total: 2) == "0 of 2")
    }

    @Test func skipHelperLine() {
        #expect(format.skipHelper(taskName: "Gym", skips: 0, dayCount: 4)
            == "No skips — every Gym day counts.")
        #expect(format.skipHelper(taskName: "Gym", skips: 1, dayCount: 4)
            == "You can miss 1 of your 4 Gym days each week and keep your streak.")
        #expect(format.skipHelper(taskName: "Gym", skips: 4, dayCount: 4)
            == "You can skip every Gym day. Your streak won't break — but it won't grow either.")
        #expect(format.skipHelper(taskName: "  ", skips: 0, dayCount: 3)
            == "No skips — every task day counts.")
    }

    @Test func nextWeekNote() {
        #expect(format.nextWeekSkipsNote(new: 2, current: 1) == "Starting next week: 2 skips (this week: 1).")
        #expect(format.nextWeekSkipsNote(new: 1, current: 0) == "Starting next week: 1 skip (this week: 0).")
    }

    @Test func skipDialog() {
        let lastOneDay = SkipPrompt(taskName: "Gym", skipsLeft: 1, daysAfterToday: [.friday])
        #expect(format.skipTitle(lastOneDay) == "Use your last skip?")
        #expect(format.skipBody(lastOneDay) == "You have 2 Gym days left this week, including today. "
            + "If you skip today, you'll have to make it Friday to keep your streak.")

        let lastSeveral = SkipPrompt(taskName: "Gym", skipsLeft: 1, daysAfterToday: [.friday, .saturday])
        #expect(format.skipBody(lastSeveral) == "You have 3 Gym days left this week, including today. "
            + "If you skip today, you'll need to check in every remaining day this week to keep your streak.")

        let lastNone = SkipPrompt(taskName: "Gym", skipsLeft: 1, daysAfterToday: [])
        #expect(format.skipBody(lastNone) == "You have 1 Gym day left this week, including today. "
            + "This keeps your streak, but you'll have no skips left until Monday.")

        let notLast = SkipPrompt(taskName: "Gym", skipsLeft: 2, daysAfterToday: [.friday])
        #expect(format.skipTitle(notLast) == "Use a skip?")
        #expect(format.skipBody(notLast) == "You have 2 Gym days left this week, including today. "
            + "You'll have 1 skip left this week after this.")
    }

    @Test func weekProgress() {
        #expect(format.weekProgress(remaining: 1) == "1 more to finish the week")
        #expect(format.weekProgress(remaining: 2) == "2 more to finish the week")
        #expect(format.weekProgress(remaining: 0) == "Week complete")
    }

    // MARK: Times and schedules

    @Test func time() {
        #expect(plain(format.time(TimeOfDay(18))) == "6:00 PM")
        #expect(plain(format.time(TimeOfDay(7, 42))) == "7:42 AM")
    }

    @Test func window() {
        #expect(plain(format.window(TimeWindow(start: TimeOfDay(18), end: TimeOfDay(20)))) == "6:00 – 8:00 PM")
        #expect(plain(format.window(TimeWindow(start: TimeOfDay(11), end: TimeOfDay(13)))) == "11:00 AM – 1:00 PM")
    }

    @Test func days() {
        #expect(format.days([.monday, .tuesday, .thursday, .friday]) == "Mon, Tue, Thu, Fri")
        #expect(format.days([.friday, .monday]) == "Mon, Fri")
        #expect(format.days(Weekday.allCases) == "Every day")
        #expect(format.days([.monday, .tuesday, .wednesday, .thursday, .friday]) == "Weekdays")
        #expect(format.days([.saturday, .sunday]) == "Sat, Sun")
    }

    @Test func scheduleSummary() {
        let window = TimeWindow(start: TimeOfDay(18), end: TimeOfDay(20))
        #expect(plain(format.schedule(days: [.monday, .tuesday, .thursday, .friday], window: window))
            == "Mon, Tue, Thu, Fri · 6:00 – 8:00 PM")
        #expect(plain(format.schedule(days: Weekday.allCases, window: window)) == "Every day · 6:00 – 8:00 PM")
    }

    @Test func nextDay() {
        #expect(format.nextDay(.tomorrow) == "Tomorrow")
        #expect(format.nextDay(.weekday(.friday)) == "Friday")
    }

    @Test func dates() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 18, minute: 42))!
        #expect(format.homeDate(date) == "Thursday, October 1")
        #expect(plain(format.photoDate(date)) == "Oct 1 · 6:42 PM")
        #expect(format.monthHeader(date) == "October 2026")
    }
}
