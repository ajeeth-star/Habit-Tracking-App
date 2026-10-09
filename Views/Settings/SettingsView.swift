import SwiftUI
import UserNotifications

/// Settings (design.md §4.13), a sheet from Today's gear: groups of rows in chunky cards, each row with a
/// colored icon badge.
/// Every choice is saved on the device through `AppSettings`. Must sit inside a `NavigationStack`.
struct SettingsView: View {
    /// Forces the "Notifications are off" warning on or off (the Design Gallery uses this);
    /// nil asks the iPhone.
    var notificationsOffOverride: Bool?
    /// Shown as a sheet from Today's gear: a "Done" button at the top right closes it.
    var showsDone = false

    @Environment(AppSettings.self) private var settings
    @Environment(TaskStore.self) private var store
    @Environment(DayStreakStore.self) private var dayStreak
    @Environment(AppRouter.self) private var router
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var notificationsDenied = false
    @State private var deleteStep: DeleteStep?
    @State private var deleteAllConfirmed = false
    @State private var showingGallery = false

    private enum DeleteStep { case confirm, final }
    private let format = Formatters.current

    var body: some View {
        @Bindable var settings = settings
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(Strings.Settings.title)
                    .font(Font.app.screenTitle)
                    .foregroundStyle(Color.app.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.horizontal, Spacing.xxs)

                SettingsSection(title: Strings.Settings.you, footer: Strings.Settings.nameFooter) {
                    SettingsRow(icon: "person.fill", color: Color.app.purple, title: Strings.Settings.yourName) {
                        TextField(Strings.Settings.namePlaceholder, text: $settings.name)
                            .font(Font.app.body)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(Color.app.textSecondary)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit { settings.finishEditingName() }
                            .accessibilityLabel(Strings.Settings.yourName)
                    }
                }

                SettingsSection(title: Strings.Settings.display) {
                    SettingsRow(icon: "flame.fill", color: Color.app.flame, title: Strings.Settings.showStreaksAs) {
                        menuPicker(Strings.Settings.showStreaksAs, selection: $settings.streakDisplay,
                                   current: settings.streakDisplay == .weeksAndDays ? Strings.Settings.weeksAndDays : Strings.Settings.daysOnly) {
                            Text(Strings.Settings.weeksAndDays).tag(StreakDisplayMode.weeksAndDays)
                            Text(Strings.Settings.daysOnly).tag(StreakDisplayMode.daysOnly)
                        }
                    }
                }

                SettingsSection(title: Strings.Settings.reminders, footer: Strings.Settings.remindersFooter) {
                    if notificationsOffOverride ?? notificationsDenied {
                        notificationsWarning
                        SettingsDivider()
                    }
                    SettingsRow(icon: "bell.fill", color: Color.app.info, title: Strings.Settings.repeatDuringWindow) {
                        menuPicker(Strings.Settings.repeatDuringWindow, selection: $settings.repeatMinutes,
                                   current: Strings.Settings.every(settings.repeatMinutes)) {
                            ForEach(AppSettings.repeatChoices, id: \.self) { Text(Strings.Settings.every($0)).tag($0) }
                        }
                    }
                    SettingsDivider()
                    SettingsRow(icon: "alarm.fill", color: StreakColor.coral.main, title: Strings.Settings.lastCall) {
                        menuPicker(Strings.Settings.lastCall, selection: $settings.lastCallMinutes,
                                   current: Strings.Settings.before(settings.lastCallMinutes)) {
                            ForEach(AppSettings.lastCallChoices, id: \.self) { Text(Strings.Settings.before($0)).tag($0) }
                        }
                    }
                }

                SettingsSection(title: Strings.Settings.feel) {
                    toggleRow("iphone.radiowaves.left.and.right", Color.app.success, Strings.Settings.vibrations,
                              $settings.vibrations)
                    SettingsDivider()
                    toggleRow("speaker.wave.2.fill", StreakColor.teal.main, Strings.Settings.sounds, $settings.sounds)
                    SettingsDivider()
                    toggleRow("sparkles", Color.app.gold, Strings.Settings.celebrationAnimation,
                              $settings.celebrationAnimation)
                }

                SettingsSection(title: Strings.Settings.streaks) {
                    NavigationLink {
                        ArchivedHabitsScreen()
                    } label: {
                        SettingsRow(icon: "archivebox.fill", color: Color.app.purple, title: Strings.Settings.archivedHabits) {
                            valueText("\(store.archived.count)")
                            chevron
                        }
                    }
                    .buttonStyle(.plain)
                }

                SettingsSection(title: Strings.Settings.yourData, footer: Strings.Settings.dataFooter) {
                    SettingsRow(icon: "photo.fill", color: Color.app.info, title: Strings.Settings.photoStorage) {
                        valueText(format.photoStorage(count: store.photoCount,
                                                      bytes: Int64(store.photoCount) * SampleData.estimatedPhotoBytes))
                    }
                    .accessibilityElement(children: .combine)
                    SettingsDivider()
                    Button {
                        withoutAnimation { deleteStep = .confirm }
                    } label: {
                        SettingsRow(icon: "trash.fill", color: Color.app.danger, title: Strings.Settings.deleteAllData,
                                    titleColor: Color.app.danger)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Strings.Settings.deleteAllData)
                }

                SettingsSection(title: Strings.Settings.about) {
                    SettingsRow(icon: "info.circle.fill", color: Color.app.textTertiary, title: Strings.Settings.version) {
                        valueText(version)
                    }
                    .accessibilityElement(children: .combine)
                }

                #if DEBUG
                SettingsSection(title: Strings.Settings.developer) {
                    Button { showingGallery = true } label: {
                        SettingsRow(icon: "paintbrush.fill", color: Color.app.textTertiary, title: Strings.Settings.designGallery) {
                            chevron
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Strings.Settings.designGallery)
                }
                #endif
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .tint(Color.app.flame)
        // Soft haptic on every toggle and picker.
        .softHaptic(trigger: settings.streakDisplay)
        .softHaptic(trigger: settings.repeatMinutes)
        .softHaptic(trigger: settings.lastCallMinutes)
        .softHaptic(trigger: settings.vibrations)
        .softHaptic(trigger: settings.sounds)
        .softHaptic(trigger: settings.celebrationAnimation)
        .background(Color.app.background)
        .toolbar {
            if showsDone {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Text(Strings.Settings.done)
                            .font(Font.app.button)
                            .foregroundStyle(Color.app.flame)
                            .frame(minWidth: Sizes.tapTarget, minHeight: Sizes.tapTarget, alignment: .trailing)
                            .contentShape(Rectangle())
                    }
                }
            }
        }
        .toolbar(showsDone ? .visible : .hidden, for: .navigationBar)
        .toolbarBackground(Color.app.background, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { settings.finishEditingName() }
        .task(id: scenePhase) {
            // Checked again whenever the app comes back, e.g. after turning notifications on.
            guard notificationsOffOverride == nil, scenePhase == .active else { return }
            let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            notificationsDenied = status == .denied
        }
        .dialogCover(isPresented: deleteDialogShown, onDismiss: deleteAllIfConfirmed) {
            deleteDialog
        }
        #if DEBUG
        .fullScreenCover(isPresented: $showingGallery) {
            DesignGalleryView()
        }
        #endif
    }

    // MARK: Pieces

    /// A menu of choices whose button shows the current one in Nunito ("Weeks and days ⌃⌄"); the list that
    /// pops up is Apple's standard menu.
    private func menuPicker<Value: Hashable, Options: View>(_ label: String, selection: Binding<Value>, current: String,
                                                        @ViewBuilder options: () -> Options) -> some View {
        Menu {
            Picker(label, selection: selection, content: options)
        } label: {
            HStack(spacing: Spacing.xxs) {
                Text(current)
                    .font(Font.app.cardTitle)
                    .monospacedDigit()
                Image(systemName: "chevron.up.chevron.down")
                    .font(Font.app.meta)
                    .fontWeight(.bold)
            }
            .foregroundStyle(Color.app.flame)
            .fixedSize()
            .frame(minHeight: Sizes.tapTarget)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
        .accessibilityValue(current)
    }

    private func toggleRow(_ icon: String, _ color: Color, _ title: String, _ isOn: Binding<Bool>) -> some View {
        SettingsRow(icon: icon, color: color, title: title) {
            Toggle(title, isOn: isOn)
                .labelsHidden()
                .tint(Color.app.success)
        }
        .accessibilityElement(children: .combine)
    }

    private func valueText(_ text: String) -> some View {
        Text(text)
            .font(Font.app.body)
            .monospacedDigit()
            .foregroundStyle(Color.app.textSecondary)
            .contentTransition(.numericText())
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(Font.app.meta)
            .fontWeight(.bold)
            .foregroundStyle(Color.app.textTertiary)
    }

    private var notificationsWarning: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.app.danger)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(Strings.Settings.notificationsOff)
                    .font(Font.app.subhead)
                    .foregroundStyle(Color.app.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(Strings.Settings.turnOn) {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                }
                .font(Font.app.button)
                .foregroundStyle(Color.app.flame)
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.app.dangerSoft)
    }

    private var version: String {
        let info = Bundle.main.infoDictionary
        return format.version(info?["CFBundleShortVersionString"] as? String ?? "",
                              build: info?["CFBundleVersion"] as? String ?? "")
    }

    // MARK: Delete all data

    private var deleteDialogShown: Binding<Bool> {
        Binding { deleteStep != nil } set: { if !$0 { deleteStep = nil } }
    }

    /// Two questions in one dialog: "Continue" swaps in the final one instead of closing.
    @ViewBuilder private var deleteDialog: some View {
        if deleteStep == .final {
            AppDialog(title: Strings.Dialog.deleteAllFinalTitle,
                      actionTitle: Strings.Dialog.deleteEverything, actionStyle: .destructive) {
                deleteAllConfirmed = true
            }
        } else {
            AppDialog(title: Strings.Dialog.deleteAllTitle, message: Strings.Dialog.deleteAllBody,
                      actionTitle: Strings.Dialog.continue, actionStyle: .neutral, closesOnAction: false) {
                deleteStep = .final
            }
        }
    }

    /// After the final dialog closes: delete everything and show the (now empty) Today tab.
    private func deleteAllIfConfirmed() {
        guard deleteAllConfirmed else { return }
        deleteAllConfirmed = false
        store.deleteAll()
        dayStreak.reset()
        router.selectedTab = .today
        if showsDone { dismiss() }
    }
}

/// Settings → Archived habits: the archived rows, always expanded.
struct ArchivedHabitsScreen: View {
    @Environment(TaskStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var openedTaskID: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(Strings.Settings.archivedHabits)
                    .font(Font.app.screenTitle)
                    .foregroundStyle(Color.app.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                if store.archived.isEmpty {
                    Text(Strings.Habits.noArchived)
                        .font(Font.app.subhead)
                        .foregroundStyle(Color.app.textSecondary)
                } else {
                    ArchivedHabitsList { openedTaskID = $0 }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.app.background)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(Font.app.button)
                        .foregroundStyle(Color.app.flame)
                        .frame(minWidth: Sizes.tapTarget, minHeight: Sizes.tapTarget, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Strings.Detail.back)
            }
        }
        .navigationDestination(item: $openedTaskID) { id in
            HabitDestination(id: id)
        }
    }
}
