import Foundation

/// One reminder to schedule.
struct PlannedReminder: Hashable, Identifiable {
    enum Kind: String { case opens, repeating = "repeat", lastCall }

    /// "reminder.<streak id>.<yyyy-mm-dd>.<kind>.<hh-mm>", unique and stable, so a streak's reminders can be found.
    var id: String
    var streakID: UUID
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
/// - the soonest first, at most `limit` (iOS keeps only 64 pending per app).
struct ReminderPlanner {
    var rules: StreakRules
    var format = Formatters.current
    var repeatMinutes: Int
    var lastCallMinutes: Int

    static let limit = 64
    /// A normal repeat never comes this close before the last call.
    static let lastCallGap: TimeInterval = 5 * 60
    /// How far ahead to look; the 64 limit is usually reached well before.
    static let daysAhead = 14

    func plan(_ streaks: [StreakData], now: Date, limit: Int = ReminderPlanner.limit) -> [PlannedReminder] {
        let today = rules.calendar.startOfDay(for: now)
        var reminders: [PlannedReminder] = []
        for streak in streaks where !streak.isArchived {
            let streakDays = rules.summary(streak, now: now).current.totalCheckIns
            for offset in 0..<Self.daysAhead {
                guard let day = rules.calendar.date(byAdding: .day, value: offset, to: today),
                      rules.outcome(streak, on: day, now: now) == .pending,
                      let version = rules.version(streak, on: day) else { continue }
                reminders += window(streak, version: version, day: day, streakDays: streakDays)
            }
        }
        return Array(reminders.filter { $0.date > now }.sorted { ($0.date, $0.id) < ($1.date, $1.id) }.prefix(limit))
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
