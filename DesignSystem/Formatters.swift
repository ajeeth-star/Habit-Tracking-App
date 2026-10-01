import Foundation

/// Turns data into display text (design.md §3). Views use `Formatters.current`, which follows the
/// phone's language and 12/24-hour setting; tests make their own with a fixed locale.
struct Formatters {
    let locale: Locale
    let calendar: Calendar

    init(locale: Locale = .autoupdatingCurrent, timeZone: TimeZone = .autoupdatingCurrent) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        calendar.timeZone = timeZone
        self.locale = locale
        self.calendar = calendar
    }

    static let current = Formatters()

    // MARK: Streaks

    /// "3 weeks 2 days", "2 days", "3 weeks", or "No streak yet".
    func streakLong(_ streak: Streak) -> String {
        var parts: [String] = []
        if streak.weeks > 0 { parts.append(Strings.Streak.weeks(streak.weeks)) }
        if streak.days > 0 { parts.append(Strings.Streak.days(streak.days)) }
        return parts.isEmpty ? Strings.Streak.none : parts.joined(separator: " ")
    }

    /// "3w 2d", "2d", "3w", or "—".
    func streakShort(_ streak: Streak) -> String {
        var parts: [String] = []
        if streak.weeks > 0 { parts.append(Strings.Streak.shortWeeks(streak.weeks)) }
        if streak.days > 0 { parts.append(Strings.Streak.shortDays(streak.days)) }
        return parts.isEmpty ? Strings.Streak.shortNone : parts.joined(separator: " ")
    }

    /// "14 days", "1 day", or "No streak yet".
    func streakDaysOnly(_ streak: Streak) -> String {
        streak.totalCheckIns == 0 ? Strings.Streak.none : Strings.Streak.days(streak.totalCheckIns)
    }

    /// The compact streak used on cards and stat tiles, following the owner's toggle.
    func streakCompact(_ streak: Streak, mode: StreakDisplayMode) -> String {
        mode == .daysOnly ? streakDaysOnly(streak) : streakShort(streak)
    }

    /// The spelled-out streak used on the success screen, following the owner's toggle.
    func streakFull(_ streak: Streak, mode: StreakDisplayMode) -> String {
        mode == .daysOnly ? streakDaysOnly(streak) : streakLong(streak)
    }

    // MARK: Skips

    /// "1 skip left", "2 skips left", or "No skips left".
    func skipsLeft(_ count: Int) -> String {
        count == 0 ? Strings.Skips.noneLeft : Strings.Skips.left(count)
    }

    /// "1 of 1".
    func skipsOfTotal(left: Int, total: Int) -> String {
        Strings.Skips.ofTotal(left, total)
    }

    // MARK: Times and schedules

    /// "6:00 PM" (short time style in the user's locale).
    func time(_ time: TimeOfDay) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date(for: time))
    }

    /// "6:00 – 8:00 PM".
    func window(_ window: TimeWindow) -> String {
        let formatter = DateIntervalFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date(for: window.start), to: date(for: window.end))
    }

    /// "Tomorrow" or "Friday".
    func nextDay(_ next: NextDay) -> String {
        switch next {
        case .tomorrow: Strings.Schedule.tomorrow
        case .weekday(let day): weekdayName(day)
        }
    }

    /// "Mon, Tue, Thu, Fri", "Every day", or "Weekdays".
    func days(_ days: [Weekday]) -> String {
        let set = Set(days)
        if set.count == 7 { return Strings.Schedule.everyDay }
        if set == [.monday, .tuesday, .wednesday, .thursday, .friday] { return Strings.Schedule.weekdays }
        return set.sorted().map(weekdayShortName).joined(separator: Strings.Schedule.listSeparator)
    }

    /// "Mon, Tue, Thu, Fri · 6:00 – 8:00 PM".
    func schedule(days: [Weekday], window: TimeWindow) -> String {
        self.days(days) + Strings.separator + self.window(window)
    }

    /// "Monday".
    func weekdayName(_ day: Weekday) -> String {
        calendar.standaloneWeekdaySymbols[day.calendarWeekday - 1]
    }

    /// "Mon".
    func weekdayShortName(_ day: Weekday) -> String {
        calendar.shortStandaloneWeekdaySymbols[day.calendarWeekday - 1]
    }

    /// "M".
    func weekdayLetter(_ day: Weekday) -> String {
        calendar.veryShortStandaloneWeekdaySymbols[day.calendarWeekday - 1]
    }

    // MARK: Dates

    /// "Thursday, October 1".
    func homeDate(_ date: Date) -> String {
        format(date, template: "EEEEMMMMd")
    }

    /// "Oct 1 · 6:42 PM".
    func photoDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return format(date, template: "MMMd") + Strings.separator + formatter.string(from: date)
    }

    /// "October 2026".
    func monthHeader(_ date: Date) -> String {
        format(date, template: "MMMMyyyy")
    }

    // MARK: Task form

    /// The live line under the skips stepper.
    func skipHelper(taskName: String, skips: Int, dayCount: Int) -> String {
        let trimmed = taskName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? Strings.Form.fallbackTaskName : trimmed
        if skips == 0 { return Strings.Form.noSkips(name) }
        if skips >= dayCount { return Strings.Form.allSkips(name) }
        return Strings.Form.someSkips(skips, dayCount, name)
    }

    /// "Starting next week: 2 skips (this week: 1)."
    func nextWeekSkipsNote(new: Int, current: Int) -> String {
        Strings.Form.nextWeek(Strings.Skips.count(new), String(current))
    }

    /// "Starting next week: Mon, Wed (this week: Mon, Tue, Thu, Fri)."
    func nextWeekDaysNote(new: [Weekday], current: [Weekday]) -> String {
        Strings.Form.nextWeek(days(new), days(current))
    }

    // MARK: Skip dialog

    func skipTitle(_ prompt: SkipPrompt) -> String {
        prompt.isLastSkip ? Strings.Skip.lastTitle : Strings.Skip.title
    }

    func skipBody(_ prompt: SkipPrompt) -> String {
        let first = Strings.Skip.daysLeft(prompt.daysLeftIncludingToday, prompt.taskName)
        let second: String
        if !prompt.isLastSkip {
            second = Strings.Skip.leftAfter(prompt.skipsLeft - 1)
        } else if prompt.daysAfterToday.isEmpty {
            second = Strings.Skip.noneUntilMonday
        } else if prompt.daysAfterToday.count == 1 {
            second = Strings.Skip.makeItOn(weekdayName(prompt.daysAfterToday[0]))
        } else {
            second = Strings.Skip.checkInEveryDay
        }
        return first + " " + second
    }

    // MARK: Check-in success

    /// "1 more to finish the week" or "Week complete".
    func weekProgress(remaining: Int) -> String {
        remaining == 0 ? Strings.Success.weekComplete : Strings.Success.moreToFinish(remaining)
    }

    // MARK: Helpers

    private func date(for time: TimeOfDay) -> Date {
        // Any fixed day without a daylight-saving change works; only the clock time is shown.
        calendar.date(from: DateComponents(year: 2001, month: 1, day: 1, hour: time.hour, minute: time.minute))!
    }

    private func format(_ date: Date, template: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date)
    }
}
