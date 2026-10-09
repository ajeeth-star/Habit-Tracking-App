import Foundation
import UserNotifications

/// Keeps the iPhone's pending reminders in step with `ReminderPlanner` (context.md §7). Local notifications only.
/// Always plans with the real time, never the DEBUG pretend clock.
@MainActor
final class ReminderScheduler {
    private let center = UNUserNotificationCenter.current()
    private let settings: AppSettings
    /// What was last handed to iOS, so nothing is rescheduled when nothing changed.
    private var scheduled: [PlannedReminder] = []

    init(settings: AppSettings) {
        self.settings = settings
    }

    /// Replaces every pending reminder with a fresh plan, if it changed.
    func reschedule(_ streaks: [StreakData], rules: StreakRules, now: Date = Date()) {
        let plan = ReminderPlanner(rules: rules, repeatMinutes: settings.repeatMinutes,
                                   lastCallMinutes: settings.lastCallMinutes).plan(streaks, now: now)
        guard plan != scheduled else { return }
        let center = center
        Task {
            // Without permission iOS refuses them; try again on the next refresh (e.g. once allowed).
            guard Self.allowed(await Self.status()) else { return }
            let pending = await center.pendingNotificationRequests()
            center.removePendingNotificationRequests(
                withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(PlannedReminder.idPrefix) })
            for reminder in plan {
                try? await center.add(Self.request(for: reminder))
            }
            scheduled = plan
        }
    }

    static func allowed(_ status: UNAuthorizationStatus) -> Bool {
        status == .authorized || status == .provisional || status == .ephemeral
    }

    /// A streak was checked in or skipped: its reminders already shown in Notification Center go too.
    func clearDelivered(for streakID: String) {
        guard let uuid = UUID(uuidString: streakID) else { return }
        let prefix = PlannedReminder.prefix(for: uuid)
        let center = center
        Task {
            let delivered = await center.deliveredNotifications()
            center.removeDeliveredNotifications(
                withIdentifiers: delivered.map(\.request.identifier).filter { $0.hasPrefix(prefix) })
        }
    }

    private static func request(for reminder: PlannedReminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        // Comes through Focus modes only if the app has Apple's time-sensitive capability (not set up yet; see the
        // reminders phase notes). Without it, iOS treats this as a normal notification.
        content.interruptionLevel = reminder.isTimeSensitive ? .timeSensitive : .active
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminder.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        return UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)
    }

    // MARK: Permission

    /// Whether reminders are allowed, not decided yet, or turned off.
    static func status() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Shows the iPhone's permission prompt (only the first time; after that iOS answers on its own).
    @discardableResult
    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    // MARK: DEBUG tools

    #if DEBUG
    /// Settings → Developer → Send test reminder in 5 seconds.
    static func sendTest() async {
        if await status() == .notDetermined { await requestPermission() }
        let content = UNMutableNotificationContent()
        content.title = Strings.Reminder.testTitle
        content.body = Strings.Reminder.testBody
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        try? await UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "test." + UUID().uuidString, content: content, trigger: trigger))
    }
    #endif
}
