#if DEBUG
import SwiftUI
import UserNotifications

/// Settings → Developer, DEBUG builds only (context.md §11): the pretend clock, sample data for testing,
/// erasing everything, and the Design Gallery.
struct DeveloperSection: View {
    let onOpenGallery: () -> Void

    @Environment(TaskStore.self) private var store
    @Environment(AppClock.self) private var clock
    @State private var confirmingErase = false
    @State private var eraseConfirmed = false

    var body: some View {
        SettingsSection(title: Strings.Settings.developer) {
            TimelineView(.everyMinute) { context in
                let now = clock.now(at: context.date)
                Text(clock.isPretending ? Strings.Developer.pretendTime(timeText(now))
                                        : Strings.Developer.realTime(timeText(now)))
                    .font(Font.app.body)
                    .monospacedDigit()
                    .foregroundStyle(clock.isPretending ? Color.app.flame : Color.app.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: Sizes.settingsRow, alignment: .leading)
                    .padding(.horizontal, Spacing.md)
                    .accessibilityIdentifier("developer.time")
            }
            SettingsDivider()
            HStack(spacing: Spacing.xs) {
                timeButton(Strings.Developer.plus15Minutes, 15 * 60)
                timeButton(Strings.Developer.plusHour, 3_600)
                timeButton(Strings.Developer.plusDay, 86_400)
                timeButton(Strings.Developer.plusWeek, 7 * 86_400)
            }
            .padding(Spacing.sm)
            SettingsDivider()
            row("clock.arrow.circlepath", Color.app.info, Strings.Developer.resetTime) { clock.resetToRealTime() }
            SettingsDivider()
            row("tray.and.arrow.down.fill", Color.app.success, Strings.Developer.fillSampleData) { store.fillSampleData() }
            SettingsDivider()
            row("trash.fill", Color.app.danger, Strings.Developer.eraseEverything) {
                withoutAnimation { confirmingErase = true }
            }
            SettingsDivider()
            row("bell.badge.fill", Color.app.flame, Strings.Developer.sendTestReminder) {
                Task {
                    await ReminderScheduler.sendTest()
                    store.refresh() // schedules the real reminders too, if they were just allowed
                }
            }
            SettingsDivider()
            NavigationLink {
                PendingRemindersView()
            } label: {
                SettingsRow(icon: "list.bullet", color: Color.app.flame, title: Strings.Developer.showPendingReminders) {
                    Image(systemName: "chevron.right")
                        .font(Font.app.meta)
                        .foregroundStyle(Color.app.textTertiary)
                }
            }
            .buttonStyle(.plain)
            SettingsDivider()
            row("paintbrush.fill", Color.app.textTertiary, Strings.Settings.designGallery, action: onOpenGallery)
        }
        .dialogCover(isPresented: $confirmingErase, onDismiss: eraseIfConfirmed) {
            AppDialog(title: Strings.Developer.eraseTitle, message: Strings.Developer.eraseBody,
                      actionTitle: Strings.Developer.eraseEverything, actionStyle: .destructive) {
                eraseConfirmed = true
            }
        }
    }

    private func eraseIfConfirmed() {
        guard eraseConfirmed else { return }
        eraseConfirmed = false
        store.deleteAll()
    }

    private func timeButton(_ title: String, _ seconds: TimeInterval) -> some View {
        Button(title) { clock.advance(by: seconds) }
            .font(Font.app.pill)
            .foregroundStyle(Color.app.info)
            .frame(maxWidth: .infinity, minHeight: Sizes.tapTarget)
            .background(Color.app.surfaceRaised, in: .rounded(Radius.sm))
            .buttonStyle(.plain)
    }

    private func row(_ icon: String, _ color: Color, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            SettingsRow(icon: icon, color: color, title: title)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func timeText(_ date: Date) -> String {
        Formatters.current.homeDate(date) + Strings.separator + Formatters.current.time(of: date)
    }
}
#endif

#if DEBUG
/// Settings → Developer → Show pending reminders: everything iOS is holding, soonest first.
struct PendingRemindersView: View {
    @State private var requests: [UNNotificationRequest] = []

    var body: some View {
        List {
            if requests.isEmpty {
                Text(Strings.Developer.noPendingReminders)
                    .font(Font.app.body)
                    .foregroundStyle(Color.app.textSecondary)
            }
            ForEach(requests, id: \.identifier) { request in
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(fireDate(request).map { Formatters.current.homeDate($0) + Strings.separator
                        + Formatters.current.time(of: $0) } ?? "")
                        .font(Font.app.meta)
                        .monospacedDigit()
                        .foregroundStyle(Color.app.flame)
                    Text(request.content.title)
                        .font(Font.app.cardTitle)
                        .foregroundStyle(Color.app.textPrimary)
                    Text(request.content.body)
                        .font(Font.app.meta)
                        .foregroundStyle(Color.app.textSecondary)
                }
                .listRowBackground(Color.app.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.app.background)
        .navigationTitle(Strings.Developer.showPendingReminders)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
            requests = pending.sorted { (fireDate($0) ?? .distantFuture) < (fireDate($1) ?? .distantFuture) }
        }
    }

    private func fireDate(_ request: UNNotificationRequest) -> Date? {
        (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
            ?? (request.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate()
    }
}
#endif
