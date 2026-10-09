#if DEBUG
import SwiftUI

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
