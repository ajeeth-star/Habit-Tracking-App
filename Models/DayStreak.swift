import Foundation

/// The flame's look, decided by the day streak (context.md §10, design.md §2b).
enum FlameForm: Int, CaseIterable, Codable, Comparable, Identifiable {
    case ember, spark, flame, blaze, bonfire, inferno, wildfire, eternal

    var id: Int { rawValue }

    /// The day streak this form starts at.
    var minimumDays: Int {
        switch self {
        case .ember: 0
        case .spark: 1
        case .flame: 7
        case .blaze: 14
        case .bonfire: 30
        case .inferno: 50
        case .wildfire: 100
        case .eternal: 365
        }
    }

    /// The form for a day streak.
    init(days: Int) {
        self = Self.allCases.last { days >= $0.minimumDays } ?? .ember
    }

    /// The next form up, or nil at Eternal.
    var next: FlameForm? { FlameForm(rawValue: rawValue + 1) }

    /// Days still needed to reach the next form, or nil at Eternal.
    static func daysToNext(from days: Int) -> (days: Int, form: FlameForm)? {
        guard let next = FlameForm(days: days).next else { return nil }
        return (next.minimumDays - days, next)
    }

    /// How far through the current form the streak is, 0…1 (1 at Eternal).
    static func progress(days: Int) -> Double {
        let form = FlameForm(days: days)
        guard let next = form.next else { return 1 }
        return Double(days - form.minimumDays) / Double(next.minimumDays - form.minimumDays)
    }

    static func < (lhs: FlameForm, rhs: FlameForm) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// How the flame looks right now (design.md §2b). Picked by `FlameStatus`; `cheering` only on celebrations.
enum FlameMood: String, CaseIterable, Identifiable {
    case happy, proud, sleepy, worried, sad, cheering

    var id: String { rawValue }
}

// MARK: - One day's scheduled items

/// One streak scheduled on one day, as the day streak sees it.
struct DayStreakItem: Hashable {
    enum Outcome: Hashable {
        case pending
        case checkedIn(at: Date)
        case skipped
    }

    var taskID: String
    var taskName: String
    var opens: Date
    var closes: Date
    var outcome: Outcome

    var isResolved: Bool { outcome != .pending }

    var isCheckIn: Bool {
        if case .checkedIn = outcome { true } else { false }
    }

    /// The window closed with no check-in and no skip.
    func isMissed(at now: Date) -> Bool { outcome == .pending && closes <= now }

    func isOpen(at now: Date) -> Bool { opens <= now && now < closes }
}

/// Everything scheduled on one day that counts toward the day streak.
struct DayRecord: Hashable {
    /// Midnight at the start of the day.
    var day: Date
    var items: [DayStreakItem]

    var isRestDay: Bool { items.isEmpty }
    /// Every item checked in or skipped, and at least one check-in.
    var isComplete: Bool { !items.isEmpty && items.allSatisfy(\.isResolved) && items.contains(where: \.isCheckIn) }
}

extension DayRecord {
    /// Today's record, built from the tasks as they stand at `now`.
    /// - Archived (and deleted) streaks aren't in it, so they stop counting the moment they leave.
    /// - A streak created today only counts if today's window opens after it was created.
    init(tasks: [TaskSnapshot], now: Date, calendar: Calendar = .current) {
        let day = calendar.startOfDay(for: now)
        func at(_ time: TimeOfDay) -> Date {
            calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: day) ?? day
        }
        let items = tasks.compactMap { task -> DayStreakItem? in
            guard !task.isArchived, case .scheduled(_, let completion) = task.today else { return nil }
            let opens = at(task.window.start)
            if let created = task.createdAt, created > opens { return nil }
            let outcome: DayStreakItem.Outcome = switch completion {
            case .none: .pending
            case .skipped: .skipped
            case .done(let time): .checkedIn(at: at(time))
            }
            return DayStreakItem(taskID: task.id, taskName: task.name, opens: opens, closes: at(task.window.end),
                                 outcome: outcome)
        }
        self.init(day: day, items: items)
    }
}

// MARK: - The saved state

/// What's saved about the day streak (context.md §10).
struct DayStreakState: Codable, Equatable {
    var current = 0
    var longest = 0
    /// The best form ever reached.
    var bestForm = FlameForm.ember
    /// The last day that added +1, so a day never counts twice.
    var lastCountedDay: Date?
    /// The last day with a missed window: it can't add any more.
    var missedDay: Date?
    /// The latest time the day streak ended (only when there was a streak to end).
    var lastBreak: Break?

    struct Break: Codable, Equatable {
        /// Midnight at the start of the day it ended.
        var day: Date
        /// When the window closed.
        var at: Date
        /// The day streak just before it ended.
        var length: Int
        /// The "streak ended" screen has been shown for this break.
        var screenShown = false
    }

    var form: FlameForm { FlameForm(days: current) }

    /// The "streak ended" screen still has to be shown for the latest break — unless the flame is already back.
    var needsEndedScreen: Bool { current == 0 && lastBreak.map { !$0.screenShown } ?? false }
}

/// What changed when a day was counted (drives the celebration's steps 2 and 3).
struct DayStreakChange: Hashable {
    var from: Int
    var to: Int
    /// The first day back after a break: "Your flame is back!"
    var isRevival: Bool

    var fromForm: FlameForm { FlameForm(days: from) }
    var toForm: FlameForm { FlameForm(days: to) }

    /// A form just reached that gets its own celebration step. Ember → Spark (0 → 1) doesn't: the
    /// day streak step already shows the flame growing.
    var newForm: FlameForm? { from > 0 && toForm > fromForm ? toForm : nil }
}

// MARK: - The rules

/// The day streak rules (context.md §10). Pure functions, so they can be tested without screens.
enum DayStreakRules {
    enum Event: Equatable {
        case grew(DayStreakChange)
        case ended(length: Int)
    }

    /// Applies one day's record as it stands at `now`. Safe to call as often as you like: a day adds at most
    /// once, and a break is recorded once.
    static func apply(_ record: DayRecord, at now: Date, to state: DayStreakState) -> (DayStreakState, [Event]) {
        var state = state
        var events: [Event] = []

        // A window closed with nothing done: the streak ends right then.
        let missed = record.items.filter { $0.isMissed(at: now) }
        if state.missedDay != record.day, let firstMiss = missed.min(by: { $0.closes < $1.closes }) {
            state.missedDay = record.day
            if state.current > 0 {
                state.lastBreak = .init(day: record.day, at: firstMiss.closes, length: state.current)
                events.append(.ended(length: state.current))
                state.current = 0
            }
        }

        // Every item resolved, at least one check-in: +1, once per day, and never on a day with a miss.
        if record.isComplete, state.lastCountedDay != record.day, state.missedDay != record.day {
            let change = DayStreakChange(from: state.current, to: state.current + 1,
                                         isRevival: state.current == 0 && state.lastBreak != nil)
            state.current += 1
            state.longest = max(state.longest, state.current)
            state.bestForm = max(state.bestForm, state.form)
            state.lastCountedDay = record.day
            events.append(.grew(change))
        }
        return (state, events)
    }

    /// Applies several days in order, e.g. after the app was closed for a while. Earlier days are
    /// looked at as they stood at their end.
    static func apply(_ records: [DayRecord], at now: Date, to state: DayStreakState,
                      calendar: Calendar = .current) -> (DayStreakState, [Event]) {
        var state = state
        var events: [Event] = []
        for record in records.sorted(by: { $0.day < $1.day }) {
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: record.day) ?? now
            let result = apply(record, at: min(now, endOfDay), to: state)
            state = result.0
            events += result.1
        }
        return (state, events)
    }
}

// MARK: - Mood and speech bubble

/// What the flame says in Today's speech bubble (design.md §4.1), first match wins.
enum FlameBubble: Hashable {
    case streakEnded
    case closingSoon(task: String, minutes: Int)
    case open(task: String)
    case upcoming(task: String, start: Date)
    case allDone
    case restDay
    /// Nothing left today, but something was missed.
    case dayOver
}

/// The flame's mood and line for today.
struct FlameStatus: Hashable {
    var mood: FlameMood
    var bubble: FlameBubble

    /// "Worried" within this many minutes of an open window closing.
    static let worriedMinutes = 15

    init(state: DayStreakState, record: DayRecord, now: Date) {
        let open = record.items
            .filter { $0.outcome == .pending && $0.isOpen(at: now) }
            .sorted { $0.closes < $1.closes }
        let closing = open.first { $0.closes.timeIntervalSince(now) <= Double(Self.worriedMinutes * 60) }
        let upcoming = record.items
            .filter { $0.outcome == .pending && now < $0.opens }
            .min { $0.opens < $1.opens }
        let allResolved = !record.items.isEmpty && record.items.allSatisfy(\.isResolved)

        // Sad: it ended today and nothing has been checked in since.
        let isSad: Bool = {
            guard let lastBreak = state.lastBreak, lastBreak.day == record.day else { return false }
            return !record.items.contains {
                if case .checkedIn(let time) = $0.outcome { time >= lastBreak.at } else { false }
            }
        }()

        mood = if isSad { .sad }
            else if closing != nil { .worried }
            else if allResolved { .proud }
            else if record.isRestDay { .sleepy }
            else { .happy }

        bubble = if isSad { .streakEnded }
            else if let closing {
                .closingSoon(task: closing.taskName,
                             minutes: max(1, Int((closing.closes.timeIntervalSince(now) / 60).rounded(.up))))
            }
            else if let first = open.min(by: { $0.opens < $1.opens }) { .open(task: first.taskName) }
            else if let upcoming { .upcoming(task: upcoming.taskName, start: upcoming.opens) }
            else if allResolved { .allDone }
            else if record.isRestDay { .restDay }
            else { .dayOver }
    }
}
