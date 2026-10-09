import SwiftUI
import UserNotifications

/// Shown once, right after the first streak is created (design.md §4.17): the flame offers reminders. "Turn on
/// reminders" shows the iPhone's permission prompt (or, if they were turned off before, opens the app's page in
/// the Settings app). No rewards or pressure for allowing.
struct ReminderPermissionView: View {
    var form = FlameForm.ember
    let onDone: () -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: Spacing.xl)
            FlameCharacterView(form: form, mood: .happy, size: Sizes.flameEmpty)
            SpeechBubble(text: Strings.Reminder.permissionBubble, centered: true)
                .padding(.top, Spacing.sm)
            Spacer(minLength: Spacing.xl)
            ChunkyButton(Strings.Reminder.turnOn, systemImage: "bell.fill") {
                Task {
                    if await ReminderScheduler.status() == .denied {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                    } else {
                        await ReminderScheduler.requestPermission()
                    }
                    onDone()
                }
            }
            Button(action: onDone) {
                Text(Strings.Reminder.notNow)
                    .font(Font.app.subhead)
                    .foregroundStyle(Color.app.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: Sizes.tapTarget)
                    .contentShape(Rectangle())
            }
            .padding(.top, Spacing.xs)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.app.background)
    }
}
