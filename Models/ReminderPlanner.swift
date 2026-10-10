import Foundation

/// One reminder to schedule.
struct PlannedReminder: Hashable, Identifiable {
    enum Kind: String { case opens, repeating = "repeat", lastCall, safetyNet }

    /// "reminder.<streak id>.<yyyy-mm-dd>.<kind>.<hh-mm>", unique and stable, so a streak's reminders can be found.
    var id: String
    /// Nil for the safety net, which isn't about one streak.
    var streakID: UUID?
    var date: Date
    var kind: Kind
    var title: String
    var body: String

    /// Last calls may come through Focus modes (context.md §7).
    var isTimeSensitive: Bool { kind == .lastCall }

    static let idPrefix = "reminder."
    static func prefix(for streakID: UUID) -> String { idPrefix + streakID.uuidString + "." }
}

/// Which reminders to schedule (context.md §7), worked out from the saved streaks. Pure, so it can be tested:
/// - only on days a streak counts, and only while today's isn't checked in or skipped;
/// - when the window opens, every `repeatMinutes` during it, and a last call `lastCallMinutes` before it closes;
/// - no repeat within 5 minutes before the last call, and none after it;
/// - the next 7 days, in tiers within `limit` (iOS keeps only 64 pending per app): every opening and last call
///   first (if even those don't fit, last calls before openings), then repeats, soonest first;
/// - and in the last place, a safety net just after the last reminder asking to open the app.
struct ReminderPlanner {
    var rules: StreakRules
    var format = Formatters.current
    var repeatMinutes: Int
    var lastCallMinutes: Int

    static let limit = 64
    /// A normal repeat never comes this close before the last call.
    static let lastCallGap: TimeInterval = 5 * 60
    /// How far ahead to plan.
    static let horizon: TimeInterval = 7 * 86_400
    /// The safety net comes this long after the last reminder.
    static let safetyNetDelay: TimeInterval = 60
    static let safetyNetID = PlannedReminder.idPrefix + "safety-net"

    func plan(_ streaks: [StreakData], now: Date, limit: Int = ReminderPlanner.limit) -> [PlannedReminder] {
        let today = rules.calendar.startOfDay(for: now)
        let end = now.addingTimeInterval(Self.horizon)
        var candidates: [PlannedReminder] = []
        for streak in streaks where !streak.isArchived {
            let streakDays = rules.summary(streak, now: now).current.totalCheckIns
            // Today plus the next 7 days, so a window exactly a week away is included.
            for offset in 0...7 {
                guard let day = rules.calendar.date(byAdding: .day, value: offset, to: today),
                      rules.outcome(streak, on: day, now: now) == .pending,
                      let version = rules.version(streak, on: day) else { continue }
                candidates += window(streak, version: version, day: day, streakDays: streakDays)
            }
        }
        candidates = candidates.filter { $0.date > now && $0.date <= end }
        guard limit > 0, !candidates.isEmpty else { return [] }

        func soonest(_ kind: PlannedReminder.Kind) -> [PlannedReminder] {
            candidates.filter { $0.kind == kind }.sorted(by: Self.isSooner)
        }
        let room = limit - 1 // the last place is the safety net's
        // Tier 1: last calls, then openings (all of both, when they fit). Tier 2: repeats in what's left.
        var chosen = Array((soonest(.lastCall) + soonest(.opens)).prefix(room))
        chosen += soonest(.repeating).prefix(room - chosen.count)
        chosen.sort(by: Self.isSooner)

        guard let last = chosen.last else { return [] }
        let safetyNet = PlannedReminder(id: Self.safetyNetID, streakID: nil,
                                        date: last.date.addingTimeInterval(Self.safetyNetDelay), kind: .safetyNet,
                                        title: Strings.Reminder.safetyNet, body: "")
        return chosen + [safetyNet]
    }

    private static func isSooner(_ a: PlannedReminder, _ b: PlannedReminder) -> Bool {
        (a.date, a.id) < (b.date, b.id)
    }

    private func window(_ streak: StreakData, version: ScheduleData, day: Date, streakDays: Int) -> [PlannedReminder] {
        let (opens, closes) = rules.window(version.window, on: day)
        let end = version.window.end
        let lastCall = closes.addingTimeInterval(-Double(lastCallMinutes * 60))
        let hasLastCall = lastCall > opens
        var reminders: [PlannedReminder] = []

        func add(_ kind: PlannedReminder.Kind, at date: Date, _ text: (title: String, body: String)) {
            reminders.append(PlannedReminder(id: id(streak, day: day, kind: kind, at: date), streakID: streak.id,
                                             date: date, kind: kind, title: text.title, body: text.body))
        }

        add(.opens, at: opens, format.reminderOpens(streak.name, end: end))

        let latestRepeat = hasLastCall ? lastCall.addingTimeInterval(-Self.lastCallGap) : closes.addingTimeInterval(-1)
        var next = opens.addingTimeInterval(Double(repeatMinutes * 60))
        while next <= latestRepeat, next < closes {
            let left = Int((closes.timeIntervalSince(next) / 60).rounded())
            add(.repeating, at: next, format.reminderRepeat(streak.name, minutesLeft: left, end: end))
            next = next.addingTimeInterval(Double(repeatMinutes * 60))
        }

        if hasLastCall {
            let skipsLeft = rules.skipsLeft(streak, now: opens)
            add(.lastCall, at: lastCall, format.reminderLastCall(streak.name, end: end, skipsLeft: skipsLeft,
                                                                 streakDays: streakDays))
        }
        return reminders
    }

    private func id(_ streak: StreakData, day: Date, kind: PlannedReminder.Kind, at date: Date) -> String {
        let d = rules.calendar.dateComponents([.year, .month, .day], from: day)
        let t = rules.calendar.dateComponents([.hour, .minute], from: date)
        let dayText = String(format: "%04d-%02d-%02d", d.year ?? 0, d.month ?? 0, d.day ?? 0)
        let timeText = String(format: "%02d-%02d", t.hour ?? 0, t.minute ?? 0)
        return PlannedReminder.prefix(for: streak.id) + "\(dayText).\(kind.rawValue).\(timeText)"
    }
}
