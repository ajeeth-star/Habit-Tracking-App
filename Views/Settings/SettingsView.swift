import SwiftUI
import UserNotifications

/// The Settings tab (design.md §4.13): a standard grouped list in the app's colors and fonts.
/// Every choice is saved on the device through `AppSettings`. Must sit inside a `NavigationStack`.
struct SettingsView: View {
    /// Forces the "Notifications are off" warning on or off (the Design Gallery uses this);
    /// nil asks the iPhone.
    var notificationsOffOverride: Bool?
    /// Shown as a sheet from Today's gear: a "Done" button at the top right closes it.
    var showsDone = false

    @Environment(AppSettings.self) private var settings
    @Environment(TaskStore.self) private var store
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
        List {
            Section {
                Text(Strings.Settings.title)
                    .font(Font.app.screenTitle)
                    .foregroundStyle(Color.app.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: Spacing.lg, bottom: 0, trailing: Spacing.lg))
            }

            Section {
                HStack {
                    Text(Strings.Settings.yourName)
                    TextField(Strings.Settings.namePlaceholder, text: $settings.name)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(Color.app.textSecondary)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit { settings.finishEditingName() }
                        .accessibilityLabel(Strings.Settings.yourName)
                }
                .listRowBackground(Color.app.surface)
            } header: {
                header(Strings.Settings.you)
            } footer: {
                footer(Strings.Settings.nameFooter)
            }

            Section {
                Group {
                    Picker(Strings.Settings.showStreaksAs, selection: $settings.streakDisplay) {
                        Text(Strings.Settings.weeksAndDays).tag(StreakDisplayMode.weeksAndDays)
                        Text(Strings.Settings.daysOnly).tag(StreakDisplayMode.daysOnly)
                    }
                    Picker(Strings.Settings.appearance, selection: $settings.appearance) {
                        Text(Strings.Settings.system).tag(AppSettings.Appearance.system)
                        Text(Strings.Settings.light).tag(AppSettings.Appearance.light)
                        Text(Strings.Settings.dark).tag(AppSettings.Appearance.dark)
                    }
                }
                .listRowBackground(Color.app.surface)
            } header: {
                header(Strings.Settings.display)
            }

            Section {
                Group {
                    if notificationsOffOverride ?? notificationsDenied {
                        notificationsWarning
                    }
                    Picker(Strings.Settings.repeatDuringWindow, selection: $settings.repeatMinutes) {
                        ForEach(AppSettings.repeatChoices, id: \.self) { Text(Strings.Settings.every($0)).tag($0) }
                    }
                    Picker(Strings.Settings.lastCall, selection: $settings.lastCallMinutes) {
                        ForEach(AppSettings.lastCallChoices, id: \.self) { Text(Strings.Settings.before($0)).tag($0) }
                    }
                }
                .listRowBackground(Color.app.surface)
            } header: {
                header(Strings.Settings.reminders)
            } footer: {
                footer(Strings.Settings.remindersFooter)
            }

            Section {
                Group {
                    Toggle(Strings.Settings.vibrations, isOn: $settings.vibrations)
                    Toggle(Strings.Settings.celebrationAnimation, isOn: $settings.celebrationAnimation)
                }
                .listRowBackground(Color.app.surface)
            } header: {
                header(Strings.Settings.feel)
            }

            Section {
                Group {
                    NavigationLink {
                        ArchivedHabitsScreen()
                    } label: {
                        LabeledContent(Strings.Settings.archivedHabits, value: "\(store.archived.count)")
                    }
                }
                .listRowBackground(Color.app.surface)
            } header: {
                header(Strings.Settings.streaks)
            }

            Section {
                Group {
                    LabeledContent(Strings.Settings.photoStorage, value: format.photoStorage(
                        count: store.photoCount, bytes: Int64(store.photoCount) * SampleData.estimatedPhotoBytes))
                    Button {
                        withoutAnimation { deleteStep = .confirm }
                    } label: {
                        Text(Strings.Settings.deleteAllData)
                            .foregroundStyle(Color.app.danger)
                    }
                }
                .listRowBackground(Color.app.surface)
            } header: {
                header(Strings.Settings.yourData)
            } footer: {
                footer(Strings.Settings.dataFooter)
            }

            Section {
                Group {
                    LabeledContent(Strings.Settings.version, value: version)
                }
                .listRowBackground(Color.app.surface)
            } header: {
                header(Strings.Settings.about)
            }

            #if DEBUG
            Section {
                Group {
                    Button(Strings.Settings.designGallery) { showingGallery = true }
                        .foregroundStyle(Color.app.accentText)
                }
                .listRowBackground(Color.app.surface)
            } header: {
                header(Strings.Settings.developer)
            }
            #endif
        }
        .listStyle(.insetGrouped)
        .font(Font.app.body)
        .foregroundStyle(Color.app.textPrimary)
        .tint(Color.app.accentText)
        .scrollContentBackground(.hidden)
        .background(Color.app.background)
        .toolbar {
            if showsDone {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Text(Strings.Settings.done)
                            .font(Font.app.button)
                            .foregroundStyle(Color.app.accentText)
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

    private func header(_ text: String) -> some View {
        Text(text)
            .font(Font.app.sectionHeader)
            .foregroundStyle(Color.app.textTertiary)
            .textCase(nil)
    }

    private func footer(_ text: String) -> some View {
        Text(text)
            .font(Font.app.meta)
            .foregroundStyle(Color.app.textSecondary)
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
                .foregroundStyle(Color.app.accentText)
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, Spacing.xxs)
        .listRowBackground(Color.app.dangerSoft)
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
                        .foregroundStyle(Color.app.accentText)
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
