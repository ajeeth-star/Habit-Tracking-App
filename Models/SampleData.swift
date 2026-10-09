import Foundation

/// Fake tasks for building and checking the screens. Nothing here is saved.
/// "Now" is one fixed pretend time, Thursday, October 1, 2026, 6:40 PM, used by every sample state and
/// Design Gallery screen so every time, countdown, and status agrees.
enum SampleData {
    static let today: Date = Calendar.current.date(
        from: DateComponents(year: 2026, month: 10, day: 1, hour: 18, minute: 40))!

    // MARK: Home — Today (window start order: 7 AM, 12 PM, 5 PM, 6 PM, 9 PM)

    /// Done this morning.
    static let skincare = TaskSnapshot(
        id: "skincare",
        name: "Morning skincare",
        days: Weekday.allCases,
        window: TimeWindow(start: TimeOfDay(7), end: TimeOfDay(9)),
        skipsPerWeek: 1, skipsLeft: 1,
        streak: Streak(weeks: 4, days: 4, totalCheckIns: 32),
        longest: Streak(weeks: 4, days: 4, totalCheckIns: 32),
        today: .scheduled(.after, .done(at: TimeOfDay(7, 42))),
        week: [
            .init(day: .monday, status: .done), .init(day: .tuesday, status: .done),
            .init(day: .wednesday, status: .done), .init(day: .thursday, status: .done),
            .init(day: .friday, status: .upcoming), .init(day: .saturday, status: .upcoming),
            .init(day: .sunday, status: .upcoming),
        ],
        checkIns: checkIns(on: Weekday.allCases, at: TimeOfDay(7, 42), count: 32),
        color: .pink, icon: "drop.fill")

    /// Window closed at lunchtime with no check-in: missed, streak ended.
    static let guitar = TaskSnapshot(
        id: "guitar",
        name: "Guitar",
        days: [.monday, .wednesday, .thursday, .saturday],
        window: TimeWindow(start: TimeOfDay(12), end: TimeOfDay(13)),
        skipsPerWeek: 1, skipsLeft: 1,
        streak: .zero,
        longest: Streak(weeks: 5, days: 1, totalCheckIns: 21),
        today: .scheduled(.after, .none),
        streakEnded: StreakEnded(on: .thursday, at: Streak(weeks: 3, days: 3, totalCheckIns: 15)),
        week: [
            .init(day: .monday, status: .done), .init(day: .wednesday, status: .done),
            .init(day: .thursday, status: .missed), .init(day: .saturday, status: .upcoming),
        ],
        checkIns: checkIns(on: [.monday, .wednesday, .thursday, .saturday], at: TimeOfDay(12, 20), count: 15, skippingToday: true),
        color: .purple, icon: "music.note")

    /// Skipped today, but the window is still open (checking in would give the skip back).
    static let run = TaskSnapshot(
        id: "run",
        name: "Run",
        days: [.tuesday, .thursday, .saturday],
        window: TimeWindow(start: TimeOfDay(17), end: TimeOfDay(19)),
        skipsPerWeek: 1, skipsLeft: 0,
        streak: Streak(weeks: 1, days: 1, totalCheckIns: 12),
        longest: Streak(weeks: 3, days: 2, totalCheckIns: 12),
        today: .scheduled(.open, .skipped),
        week: [
            .init(day: .tuesday, status: .done), .init(day: .thursday, status: .skipped),
            .init(day: .saturday, status: .upcoming),
        ],
        checkIns: checkIns(on: [.tuesday, .thursday, .saturday], at: TimeOfDay(17, 35), count: 12, skippingToday: true),
        color: .green, icon: "figure.run")

    /// Window open now, last skip left.
    static let gym = TaskSnapshot(
        id: "gym",
        name: "Gym",
        days: [.monday, .tuesday, .thursday, .friday],
        window: TimeWindow(start: TimeOfDay(18), end: TimeOfDay(20)),
        skipsPerWeek: 1, skipsLeft: 1,
        streak: Streak(weeks: 3, days: 2, totalCheckIns: 14),
        longest: Streak(weeks: 5, days: 1, totalCheckIns: 21),
        today: .scheduled(.open, .none),
        week: [
            .init(day: .monday, status: .done), .init(day: .tuesday, status: .done),
            .init(day: .thursday, status: .today), .init(day: .friday, status: .upcoming),
        ],
        checkIns: checkIns(on: [.monday, .tuesday, .thursday, .friday], at: TimeOfDay(18, 42), count: 14),
        color: .coral, icon: "dumbbell.fill")

    // Opens later tonight. Skipped on Wednesday, so that day in the week strip is only partly done.
    static let journal = TaskSnapshot(
        id: "journal",
        name: "Journal",
        days: [.monday, .tuesday, .wednesday, .thursday, .friday],
        window: TimeWindow(start: TimeOfDay(21), end: TimeOfDay(22)),
        skipsPerWeek: 2, skipsLeft: 1,
        streak: Streak(weeks: 0, days: 2, totalCheckIns: 2),
        longest: Streak(weeks: 2, days: 0, totalCheckIns: 10),
        today: .scheduled(.before, .none),
        week: [
            .init(day: .monday, status: .done), .init(day: .tuesday, status: .done),
            .init(day: .wednesday, status: .skipped), .init(day: .thursday, status: .today),
            .init(day: .friday, status: .upcoming),
        ],
        checkIns: checkIns(on: [.monday, .tuesday, .thursday, .friday], at: TimeOfDay(21, 15), count: 2),
        color: .teal, icon: "pencil")

    // MARK: Home — Not today

    static let climbing = TaskSnapshot(
        id: "climbing",
        name: "Climbing",
        days: [.tuesday, .friday],
        window: TimeWindow(start: TimeOfDay(20), end: TimeOfDay(22)),
        skipsPerWeek: 0, skipsLeft: 0,
        streak: Streak(weeks: 0, days: 1, totalCheckIns: 4),
        longest: Streak(weeks: 1, days: 1, totalCheckIns: 4),
        today: .notToday(next: .tomorrow),
        week: [.init(day: .tuesday, status: .done), .init(day: .friday, status: .upcoming)],
        checkIns: checkIns(on: [.tuesday, .friday], at: TimeOfDay(20, 30), count: 4),
        color: .blue, icon: "heart.fill")

    /// A long name, to check wrapping.
    static let walk = TaskSnapshot(
        id: "walk",
        name: "Long Sunday walk with the dog and a podcast",
        days: [.sunday],
        window: TimeWindow(start: TimeOfDay(10), end: TimeOfDay(12)),
        skipsPerWeek: 0, skipsLeft: 0,
        streak: .zero,
        longest: .zero,
        today: .notToday(next: .weekday(.sunday)),
        week: [.init(day: .sunday, status: .upcoming)],
        checkIns: [],
        color: .orange, icon: "figure.walk")

    /// Every Home state at once.
    static let allTasks = [skincare, guitar, run, gym, journal, climbing, walk]

    /// Archived three weeks ago: no current streak, best streak and photos kept.
    static let meditation = TaskSnapshot(
        id: "meditation",
        name: "Meditation",
        days: [.monday, .wednesday, .friday],
        window: TimeWindow(start: TimeOfDay(7), end: TimeOfDay(7, 30)),
        skipsPerWeek: 1, skipsLeft: 1,
        streak: .zero,
        longest: Streak(weeks: 5, days: 1, totalCheckIns: 16),
        today: .notToday(next: .tomorrow),
        week: [],
        checkIns: Array(checkIns(on: [.monday, .wednesday, .friday], at: TimeOfDay(7, 10), count: 25).dropFirst(9)),
        isArchived: true,
        color: .purple, icon: "brain.head.profile")

    /// What the app starts with: every Home state plus one archived habit.
    static let allTasksWithArchived = allTasks + [meditation]

    // MARK: Day streak

    /// Going into today: 23 days (a Blaze), longest 30, best form Bonfire. Guitar was missed at 1 PM
    /// today, so with the main sample tasks it has just ended.
    static let dayStreak = DayStreakState(
        current: 23, longest: 30, bestForm: .bonfire,
        lastCountedDay: Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: today)))

    /// The main tasks with Guitar checked in at lunch instead of missed: a healthy day for the flame.
    static let healthyTasks = allTasksWithArchived.map {
        $0.id == guitar.id ? guitar.checkedIn(at: time(12, 20)) : $0
    }

    /// Healthy, with Gym checked in too: only Journal is left, at 9 PM.
    static let healthyUpcomingTasks = healthyTasks.map { $0.id == gym.id ? gym.checkedIn(at: time(18, 12)) : $0 }

    /// Healthy, and Gym is the last thing left today: checking it in completes the day.
    static let lastOneLeftTasks = healthyTasks.filter { $0.id != journal.id }

    /// After the miss: Gym checked in since and Journal skipped, so nothing is left today.
    static let dayOverTasks = allTasksWithArchived.map { task -> TaskSnapshot in
        switch task.id {
        case gym.id: return gym.checkedIn(at: time(18, 12))
        case journal.id:
            var skipped = journal
            skipped.today = .scheduled(.before, .skipped)
            return skipped
        default: return task
        }
    }

    /// Rough size of one compressed check-in photo, for the Settings storage line until real photos exist.
    static let estimatedPhotoBytes: Int64 = 270_000

    // MARK: Task screen variants

    /// Window open, no skips left.
    static let gymNoSkips: TaskSnapshot = {
        var task = gym
        task.skipsLeft = 0
        return task
    }()

    /// Created today: no history yet.
    static let reading = TaskSnapshot(
        id: "reading",
        name: "Reading",
        days: [.thursday, .saturday],
        window: TimeWindow(start: TimeOfDay(21, 30), end: TimeOfDay(22, 30)),
        skipsPerWeek: 1, skipsLeft: 1,
        streak: .zero,
        longest: .zero,
        today: .scheduled(.before, .none),
        week: [.init(day: .thursday, status: .today), .init(day: .saturday, status: .upcoming)],
        checkIns: [],
        color: .orange, icon: "book.fill")

    // MARK: Skip dialog variants

    /// Last skip, one scheduled day after today: "make it Friday".
    static let skipLastOneDayLeft = gym.skipPrompt
    static let skipLastSeveralDaysLeft = SkipPrompt(taskName: "Gym", skipsLeft: 1, daysAfterToday: [.friday, .saturday])
    static let skipLastNoDaysLeft = SkipPrompt(taskName: "Gym", skipsLeft: 1, daysAfterToday: [])
    static let skipNotLast = SkipPrompt(taskName: "Gym", skipsLeft: 2, daysAfterToday: [.friday])

    // MARK: Home variants

    /// 7:48 PM: Gym's window closes in 12 minutes.
    static let closingSoon = time(19, 48)

    /// Everything scheduled today is checked in.
    static let allDoneTasks = [
        skincare,
        run.checkedIn(at: time(17, 20)),
        gym.checkedIn(at: time(18, 12)),
        climbing,
        walk,
    ]

    /// Gym already checked in: nothing open right now, next is Journal at 9 PM.
    static let inProgressTasks = allTasksWithArchived.map { $0.id == gym.id ? gym.checkedIn(at: time(18, 12)) : $0 }

    /// Nothing scheduled today (Thursday): Climbing is next, tomorrow.
    static let restDayTasks = [climbing, walk, meditation]

    /// Nothing scheduled today, and nothing tomorrow either: the next one is Sunday.
    static let restDayLaterTasks = [walk]

    // MARK: Streak celebration variants

    /// Gym, 14 → 15 days, Friday still to go.
    static let celebrationMidWeek = gym.checkInResult(at: today)
    static let celebrationTwoLeft = CheckInResult(
        taskName: "Journal", color: .teal, previousStreakDays: 3, streak: Streak(weeks: 0, days: 4, totalCheckIns: 4),
        remainingThisWeek: 2)
    static let celebrationWeekComplete = CheckInResult(
        taskName: "Climbing", color: .blue, previousStreakDays: 4, streak: Streak(weeks: 1, days: 0, totalCheckIns: 5),
        remainingThisWeek: 0)
    /// Run was skipped earlier today; checking in gives the skip back.
    static let celebrationSkipRefunded = run.checkInResult(at: today)

    // MARK: Helpers

    /// Today (sample) at the given clock time.
    static func time(_ hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: today)!
    }

    /// Fake check-in times going back from today, on the given days, newest first.
    private static func checkIns(on days: [Weekday], at time: TimeOfDay, count: Int, skippingToday: Bool = false) -> [Date] {
        let calendar = Calendar.current
        let weekdays = Set(days.map(\.calendarWeekday))
        var dates: [Date] = []
        var day = calendar.startOfDay(for: today)
        if skippingToday { day = calendar.date(byAdding: .day, value: -1, to: day)! }
        while dates.count < count {
            if weekdays.contains(calendar.component(.weekday, from: day)),
               let date = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: day),
               date <= today {
                dates.append(date)
            }
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return dates
    }
}
