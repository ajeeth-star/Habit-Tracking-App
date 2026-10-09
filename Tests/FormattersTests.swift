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
            == "No skips — every streak day counts.")
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

    @Test("Closes in", arguments: [
        (80, "Closes in 1h 20m"),
        (120, "Closes in 2h"),
        (59, "Closes in 59m"),
        (12, "Closes in 12m"),
        (1, "Closes in 1m"),
    ])
    func closesIn(minutes: Int, expected: String) {
        #expect(format.closesIn(minutes: minutes) == expected)
    }

    @Test func statusLine() {
        let gym = TodaySummary.NextUp(taskName: "Gym", day: nil, start: TimeOfDay(18))
        let open = TodaySummary.NextUp(taskName: "Gym", day: nil, start: TimeOfDay(18), isOpenNow: true)
        let guitar = TodaySummary.NextUp(taskName: "Guitar", day: .tomorrow, start: TimeOfDay(21))
        let friday = TodaySummary.NextUp(taskName: "Gym", day: .weekday(.friday), start: TimeOfDay(18))

        let inProgress = format.statusLine(TodaySummary(done: 2, total: 3, nextUp: gym))
        #expect(inProgress.emphasis == "2 of 3")
        #expect(plain(inProgress.rest) == " done today · Next: Gym at 6:00 PM")
        #expect(format.statusText(TodaySummary(done: 2, total: 3, nextUp: open)) == "2 of 3 done today · Gym is open now")
        #expect(plain(format.statusText(TodaySummary(done: 3, total: 3, nextUp: guitar)))
            == "All done for today · Next: Guitar tomorrow at 9:00 PM")
        #expect(format.statusLine(TodaySummary(done: 3, total: 3, nextUp: guitar)).emphasis == nil)
        #expect(plain(format.statusText(TodaySummary(done: 0, total: 0, nextUp: friday)))
            == "Rest day · Next: Gym Friday at 6:00 PM")
        #expect(format.statusText(TodaySummary(done: 1, total: 2, nextUp: nil)) == "1 of 2 done today")
    }

    @Test func nextUp() {
        let today = TodaySummary.NextUp(taskName: "Gym", day: nil, start: TimeOfDay(18))
        let tomorrow = TodaySummary.NextUp(taskName: "Guitar", day: .tomorrow, start: TimeOfDay(21))
        let later = TodaySummary.NextUp(taskName: "Walk", day: .weekday(.sunday), start: TimeOfDay(10))
        #expect(plain(format.nextUp(today)) == "Next: Gym at 6:00 PM")
        #expect(plain(format.nextUp(tomorrow)) == "Next: Guitar tomorrow at 9:00 PM")
        #expect(plain(format.nextUp(later)) == "Next: Walk Sunday at 10:00 AM")
    }

    @Test func donePill() {
        #expect(plain(StatusPill(kind: .done(format.time(TimeOfDay(7, 42)))).text) == "Done 7:42 AM")
        #expect(StatusPill(kind: .done(nil)).text == "Done")
        #expect(StatusPill(kind: .open).text == "Open now")
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

    @Test func comingUp() {
        #expect(plain(format.comingUp(daysAhead: 1, weekday: .friday, start: TimeOfDay(21))) == "Tomorrow, 9:00 PM")
        #expect(plain(format.comingUp(daysAhead: 3, weekday: .sunday, start: TimeOfDay(10))) == "Sunday, 10:00 AM")
    }

    @Test func bestStreak() {
        #expect(format.best(Streak(weeks: 5, days: 1, totalCheckIns: 21), mode: .weeksAndDays) == "Best: 5w 1d")
        #expect(format.best(Streak(weeks: 5, days: 1, totalCheckIns: 21), mode: .daysOnly) == "Best: 21 days")
        #expect(format.best(.zero, mode: .weeksAndDays) == "Best: —")
    }

    @Test func historyDayHeaders() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 18))!
        let day = { (offset: Int) in calendar.date(byAdding: .day, value: offset, to: now)! }
        #expect(format.historyDay(day(0), now: now) == "Today")
        #expect(format.historyDay(day(-1), now: now) == "Yesterday")
        #expect(format.historyDay(day(-7), now: now) == "Thursday, Sep 24")
    }

    @Test func historyNotes() {
        let date = Date()
        #expect(format.historyNote(HistoryEvent(taskID: "g", taskName: "Gym", date: date, kind: .skip)) == "Skipped Gym")
        #expect(format.historyNote(HistoryEvent(taskID: "g", taskName: "Guitar", date: date,
            kind: .miss(streakEnded: Streak(weeks: 2, days: 1, totalCheckIns: 9)))) == "Missed Guitar · streak ended at 2w 1d")
        #expect(format.historyNote(HistoryEvent(taskID: "g", taskName: "Guitar", date: date, kind: .miss(streakEnded: nil)))
            == "Missed Guitar")
    }

    @Test func settingsValues() {
        #expect(format.photoStorage(count: 0, bytes: 0) == "No photos")
        #expect(format.photoStorage(count: 142, bytes: 38_000_000).hasPrefix("142 photos · "))
        #expect(format.photoStorage(count: 1, bytes: 270_000).hasPrefix("1 photo · "))
        #expect(format.version("0.1.0", build: "1") == "0.1.0 (1)")
        #expect(Strings.counted("Done today", 2) == "Done today · 2")
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
