#if DEBUG
import SwiftUI

/// Developer tool, DEBUG builds only: every screen in every state, filled with `SampleData`,
/// so the designs can be checked in the simulator (VS Code can't show SwiftUI previews).
/// Opened from Settings → Developer → Design Gallery. This file isn't compiled into Release builds.
struct DesignGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @State private var path: [String] = []
    @State private var presented: GalleryEntry?

    var body: some View {
        @Bindable var settings = settings
        NavigationStack(path: $path) {
            List {
                Section {
                    Picker("Streaks", selection: $settings.streakDisplay) {
                        Text("Weeks + days").tag(StreakDisplayMode.weeksAndDays)
                        Text("Days only").tag(StreakDisplayMode.daysOnly)
                    }
                } footer: {
                    Text("Each entry gets its own copy of the sample data, so nothing you do here changes the app.")
                }
                ForEach(GalleryEntry.sections, id: \.self) { section in
                    Section(section) {
                        ForEach(GalleryEntry.all.filter { $0.section == section }) { entry in
                            Button {
                                open(entry)
                            } label: {
                                HStack {
                                    Text(entry.title).foregroundStyle(Color.primary)
                                    Spacer()
                                    Image(systemName: entry.presentation == .push ? "chevron.right" : "rectangle.portrait.on.rectangle.portrait")
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Design Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationDestination(for: String.self) { id in
                if let entry = GalleryEntry.all.first(where: { $0.id == id }) {
                    entry.content { path.removeLast() }
                }
            }
        }
        // Sheets can be swiped down to close, which the full-app entries rely on.
        .sheet(item: sheetBinding) { entry in
            entry.content { presented = nil }
        }
        .fullScreenCover(item: coverBinding) { entry in
            entry.content { presented = nil }
        }
    }

    private func open(_ entry: GalleryEntry) {
        switch entry.presentation {
        case .push: path.append(entry.id)
        case .sheet, .cover: presented = entry
        }
    }

    private var sheetBinding: Binding<GalleryEntry?> {
        Binding { presented?.presentation == .sheet ? presented : nil } set: { presented = $0 }
    }

    private var coverBinding: Binding<GalleryEntry?> {
        Binding { presented?.presentation == .cover ? presented : nil } set: { presented = $0 }
    }
}

/// `-galleryEntry <id>` on launch: one entry as the whole screen, so it can be screenshotted.
struct GalleryEntryRoot: View {
    let id: String

    var body: some View {
        if let entry = GalleryEntry.all.first(where: { $0.id == id }) {
            if entry.presentation == .push {
                NavigationStack { entry.content {} }
            } else {
                entry.content {}
            }
        } else {
            Text("No gallery entry \"\(id)\"")
        }
    }
}

/// Gives a gallery entry its own copy of the sample data (and its own tab selection), kept for as
/// long as the entry is open, so trying things out never changes the app's real state.
private struct SampleScope<Content: View>: View {
    @State private var store: TaskStore
    @State private var router: AppRouter
    /// Only when the entry sets a name: its own settings, kept off the device.
    @State private var namedSettings: AppSettings?
    @ViewBuilder let content: Content

    init(tasks: [TaskSnapshot] = SampleData.allTasksWithArchived, now: Date = SampleData.today,
         tab: AppRouter.Tab = .today, name: String? = nil, @ViewBuilder content: () -> Content) {
        _store = State(initialValue: TaskStore(tasks: tasks, now: now, frozen: true))
        let router = AppRouter()
        router.selectedTab = tab
        _router = State(initialValue: router)
        _namedSettings = State(initialValue: name.map { name in
            let suite = "gallery.\(UUID().uuidString)"
            let settings = AppSettings(defaults: UserDefaults(suiteName: suite)!)
            settings.name = name
            UserDefaults().removePersistentDomain(forName: suite)
            return settings
        })
        self.content = content()
    }

    var body: some View {
        if let namedSettings {
            content.environment(store).environment(router).environment(namedSettings)
        } else {
            content.environment(store).environment(router)
        }
    }
}

/// A task screen bound to the entry's own sample store, so checking in from it sticks.
private struct GalleryTaskDetail: View {
    let id: String
    @Environment(TaskStore.self) private var store

    var body: some View {
        if let task = store.binding(for: id) {
            TaskDetailView(task: task, now: store.now())
        }
    }
}

/// One screen in one state.
struct GalleryEntry: Identifiable {
    enum Presentation { case push, sheet, cover }

    let id: String
    let section: String
    let title: String
    var presentation = Presentation.push
    /// Builds the screen. The closure it receives closes the entry.
    let build: (_ close: @escaping () -> Void) -> AnyView

    func content(close: @escaping () -> Void) -> AnyView { build(close) }

    static var sections: [String] {
        var seen: [String] = []
        for entry in all where !seen.contains(entry.section) { seen.append(entry.section) }
        return seen
    }

    static let all: [GalleryEntry] = today + habits + allHistory + settings + dialogs
        + detail + form + skip + checkIn + history + components

    // MARK: Tabs (shown with the tab bar; swipe down to close)

    private static func app(_ id: String, _ section: String, _ title: String,
                            tasks: [TaskSnapshot] = SampleData.allTasksWithArchived,
                            now: Date = SampleData.today, tab: AppRouter.Tab,
                            start: MainTabView.StartState = .init(), name: String? = nil) -> GalleryEntry {
        GalleryEntry(id: id, section: section, title: title, presentation: .sheet) { _ in
            AnyView(SampleScope(tasks: tasks, now: now, tab: tab, name: name) { MainTabView(start: start) })
        }
    }

    private static let today: [GalleryEntry] = [
        app("today.busy", "Today tab", "Status · Gym is open now", tab: .today),
        app("today.inProgress", "Today tab", "Status · in progress, next later today",
            tasks: SampleData.inProgressTasks, tab: .today),
        app("today.allDone", "Today tab", "Status · all done", tasks: SampleData.allDoneTasks, tab: .today),
        app("today.restDay", "Today tab", "Status · rest day (next tomorrow)", tasks: SampleData.restDayTasks, tab: .today),
        app("today.restDayLater", "Today tab", "Status · rest day (next on a weekday)",
            tasks: SampleData.restDayLaterTasks, tab: .today),
        app("today.empty", "Today tab", "Empty (no streaks)", tasks: [], tab: .today),
        app("today.named", "Today tab", "Greeting with a name", tab: .today, name: "Ajeeth"),
        app("today.doneOpen", "Today tab", "Done today expanded", tab: .today, start: .init(showsDone: true)),
        app("today.closingSoon", "Today tab", "Hero card · closes in under 15 min", now: SampleData.closingSoon, tab: .today),
    ]

    private static let habits: [GalleryEntry] = [
        app("streaks.list", "Streaks tab", "Active · Archived collapsed", tab: .streaks),
        app("streaks.archivedOpen", "Streaks tab", "Archived expanded", tab: .streaks, start: .init(showsArchived: true)),
        app("streaks.onlyArchived", "Streaks tab", "No active streaks · one archived",
            tasks: [SampleData.meditation], tab: .streaks),
        app("streaks.empty", "Streaks tab", "Empty", tasks: [], tab: .streaks),
        GalleryEntry(id: "streaks.archivedScreen", section: "Streaks tab", title: "Archived streak screen") { _ in
            AnyView(SampleScope { ArchivedHabitView(task: SampleData.meditation) })
        },
    ]

    /// History as it looks pushed from Today (in the app the tab bar is hidden there).
    private static func historyEntry(_ id: String, _ title: String, tasks: [TaskSnapshot] = SampleData.allTasksWithArchived,
                                     filter: String? = nil, focus: HistoryFocus? = nil) -> GalleryEntry {
        GalleryEntry(id: "allHistory.\(id)", section: "History (pushed from Today)", title: title) { _ in
            AnyView(SampleScope(tasks: tasks) { AllHistoryView(filter: filter, focus: focus) })
        }
    }

    private static func day(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: SampleData.today))!
    }

    private static let allHistory: [GalleryEntry] = [
        historyEntry("all", "All streaks"),
        historyEntry("filtered", "Filtered to Guitar (a miss)", filter: SampleData.guitar.id),
        historyEntry("tuesday", "Opened from Tuesday", focus: HistoryFocus(day: day(-2), nothingScheduled: false)),
        historyEntry("nothingScheduled", "Opened from a day with nothing scheduled",
                     tasks: [SampleData.climbing], focus: HistoryFocus(day: day(-1), nothingScheduled: true)),
        historyEntry("noCheckIns", "Empty day · \"No check-ins\" wording",
                     tasks: [SampleData.climbing], focus: HistoryFocus(day: day(-3), nothingScheduled: false)),
        historyEntry("empty", "Empty", tasks: []),
    ]

    private static func settingsSheet(_ id: String, _ title: String, notificationsOff: Bool) -> GalleryEntry {
        GalleryEntry(id: id, section: "Settings (sheet from the gear)", title: title, presentation: .sheet) { _ in
            AnyView(SampleScope {
                NavigationStack { SettingsView(notificationsOffOverride: notificationsOff, showsDone: true) }
            })
        }
    }

    private static let settings: [GalleryEntry] = [
        settingsSheet("settings.default", "Settings", notificationsOff: false),
        settingsSheet("settings.notificationsOff", "Notifications off warning", notificationsOff: true),
        GalleryEntry(id: "settings.archived", section: "Settings (sheet from the gear)", title: "Archived streaks list") { _ in
            AnyView(SampleScope { ArchivedHabitsScreen() })
        },
        GalleryEntry(id: "settings.archivedEmpty", section: "Settings (sheet from the gear)",
                     title: "Archived streaks list · empty") { _ in
            AnyView(SampleScope(tasks: SampleData.allTasks) { ArchivedHabitsScreen() })
        },
    ]

    // MARK: Confirmations (over the screen they come from)

    private static func dialog(_ id: String, _ title: String, @ViewBuilder background: @escaping () -> some View,
                               @ViewBuilder dialog: @escaping () -> some View) -> GalleryEntry {
        GalleryEntry(id: "dialog.\(id)", section: "Confirmations", title: title, presentation: .cover) { _ in
            AnyView(SampleScope {
                ZStack {
                    background()
                    dialog()
                }
            })
        }
    }

    private static let dialogs: [GalleryEntry] = [
        dialog("archive", "Archive Gym?") {
            TaskFormView(mode: .edit(SampleData.gym), scrollAnchor: .bottom)
        } dialog: {
            AppDialog(title: Strings.Dialog.archiveTitle("Gym"), message: Strings.Dialog.archiveBody,
                      actionTitle: Strings.Dialog.archive, actionStyle: .neutral) {}
        },
        dialog("delete", "Delete Gym?") {
            TaskFormView(mode: .edit(SampleData.gym), scrollAnchor: .bottom)
        } dialog: {
            AppDialog(title: Strings.Dialog.deleteTitle("Gym"), message: Strings.Dialog.deleteBody,
                      actionTitle: Strings.Dialog.delete, actionStyle: .destructive) {}
        },
        dialog("deleteAll1", "Delete all data · step 1") {
            NavigationStack { SettingsView(notificationsOffOverride: false, showsDone: true) }
        } dialog: {
            AppDialog(title: Strings.Dialog.deleteAllTitle, message: Strings.Dialog.deleteAllBody,
                      actionTitle: Strings.Dialog.continue, actionStyle: .neutral) {}
        },
        dialog("deleteAll2", "Delete all data · step 2") {
            NavigationStack { SettingsView(notificationsOffOverride: false, showsDone: true) }
        } dialog: {
            AppDialog(title: Strings.Dialog.deleteAllFinalTitle,
                      actionTitle: Strings.Dialog.deleteEverything, actionStyle: .destructive) {}
        },
    ]

    // MARK: Task screen

    private static let detail: [GalleryEntry] = [
        detailEntry("open", "Open now · last skip", SampleData.gym),
        detailEntry("openNoSkips", "Open now · no skips left", SampleData.gymNoSkips),
        detailEntry("upcoming", "Before the window opens", SampleData.journal),
        detailEntry("done", "Done today", SampleData.skincare),
        detailEntry("skipped", "Skipped · window still open", SampleData.run),
        detailEntry("missed", "Missed · streak ended", SampleData.guitar),
        detailEntry("notToday", "Not today", SampleData.climbing),
        detailEntry("new", "New task · no check-ins", SampleData.reading),
    ]

    private static func detailEntry(_ id: String, _ title: String, _ task: TaskSnapshot) -> GalleryEntry {
        GalleryEntry(id: "detail.\(id)", section: "Task screen", title: title) { _ in
            AnyView(SampleScope(tasks: [task]) { GalleryTaskDetail(id: task.id) })
        }
    }

    // MARK: Create / edit

    private static let form: [GalleryEntry] = [
        formEntry("create", "New task · empty", .create, nil),
        formEntry("filled", "New task · filled in", .create, TaskFormView.Draft(
            name: "Gym", days: [.monday, .tuesday, .thursday, .friday],
            window: TimeWindow(start: TimeOfDay(18), end: TimeOfDay(20)), skips: 1)),
        formEntry("allSkips", "New task · skips = days", .create, TaskFormView.Draft(
            name: "Guitar", days: [.wednesday, .saturday],
            window: TimeWindow(start: TimeOfDay(12), end: TimeOfDay(13)), skips: 2, color: .purple)),
        formEntry("invalid", "New task · end before start", .create, TaskFormView.Draft(
            name: "Run", days: [.tuesday],
            window: TimeWindow(start: TimeOfDay(19), end: TimeOfDay(17)), skips: 0, color: .green)),
        formEntry("edit", "Edit · no changes", .edit(SampleData.gym), nil),
        formEntry("editBottom", "Edit · Archive and Delete buttons", .edit(SampleData.gym), nil, anchor: .bottom),
        formEntry("editPending", "Edit · next-week changes", .edit(SampleData.gym), TaskFormView.Draft(
            name: "Gym", days: [.monday, .tuesday, .wednesday, .thursday, .friday],
            window: SampleData.gym.window, skips: 2)),
    ]

    private static func formEntry(_ id: String, _ title: String, _ mode: TaskFormView.Mode,
                                  _ draft: TaskFormView.Draft?, anchor: UnitPoint = .top) -> GalleryEntry {
        GalleryEntry(id: "form.\(id)", section: "Create / edit task", title: title, presentation: .sheet) { _ in
            AnyView(SampleScope { TaskFormView(mode: mode, draft: draft, scrollAnchor: anchor) })
        }
    }

    // MARK: Skip dialog

    private static let skip: [GalleryEntry] = [
        skipEntry("lastOneDay", "Last skip · one day left after today", SampleData.skipLastOneDayLeft),
        skipEntry("lastSeveral", "Last skip · several days left", SampleData.skipLastSeveralDaysLeft),
        skipEntry("lastNone", "Last skip · last day of the week", SampleData.skipLastNoDaysLeft),
        skipEntry("notLast", "Not the last skip", SampleData.skipNotLast),
    ]

    private static func skipEntry(_ id: String, _ title: String, _ prompt: SkipPrompt) -> GalleryEntry {
        GalleryEntry(id: "skip.\(id)", section: "Skip dialog", title: title, presentation: .cover) { _ in
            AnyView(SampleScope {
                ZStack {
                    NavigationStack { TaskDetailView(task: .constant(SampleData.gym)) }
                    SkipConfirmationView(prompt: prompt)
                }
            })
        }
    }

    // MARK: Check-in

    private static let checkIn: [GalleryEntry] = [
        GalleryEntry(id: "camera", section: "Check-in", title: "Camera", presentation: .cover) { close in
            AnyView(CameraView(taskName: "Gym", closesAt: TimeOfDay(20), onClose: close, onCapture: close))
        },
        GalleryEntry(id: "camera.closed", section: "Check-in", title: "Camera · window closed", presentation: .cover) { close in
            AnyView(CameraView(taskName: "Gym", closesAt: TimeOfDay(20), windowClosed: true,
                               onClose: close, onCapture: close))
        },
        GalleryEntry(id: "preview", section: "Check-in", title: "Photo preview", presentation: .cover) { close in
            AnyView(PhotoPreviewView(taskName: "Gym", closesAt: TimeOfDay(20), onRetake: close, onSubmit: close))
        },
        celebrationEntry("midWeek", "Celebration · 1 more this week", SampleData.celebrationMidWeek),
        celebrationEntry("twoLeft", "Celebration · 2 more this week", SampleData.celebrationTwoLeft),
        celebrationEntry("complete", "Celebration · week complete", SampleData.celebrationWeekComplete),
        celebrationEntry("refund", "Celebration · skip given back", SampleData.celebrationSkipRefunded),
        GalleryEntry(id: "celebration.auto", section: "Check-in", title: "Celebration · closes on its own", presentation: .cover) { close in
            AnyView(StreakCelebrationView(result: SampleData.celebrationMidWeek, onDone: close))
        },
        GalleryEntry(id: "flow", section: "Check-in", title: "Whole flow (tap through)", presentation: .cover) { _ in
            AnyView(CheckInFlowView(task: SampleData.gym, now: SampleData.today))
        },
    ]

    /// Stays on screen (tap to close), so it can be looked at.
    private static func celebrationEntry(_ id: String, _ title: String, _ result: CheckInResult) -> GalleryEntry {
        GalleryEntry(id: "celebration.\(id)", section: "Check-in", title: title, presentation: .cover) { close in
            AnyView(StreakCelebrationView(result: result, closesAutomatically: false, onDone: close))
        }
    }

    // MARK: Per-task history

    private static let history: [GalleryEntry] = [
        GalleryEntry(id: "history.photos", section: "Per-task history", title: "With photos") { _ in
            AnyView(HistoryView(task: SampleData.skincare))
        },
        GalleryEntry(id: "history.empty", section: "Per-task history", title: "Empty") { _ in
            AnyView(HistoryView(task: SampleData.reading))
        },
    ]

    // MARK: Components

    private static let components: [GalleryEntry] = [
        GalleryEntry(id: "components", section: "Components", title: "All components") { _ in
            AnyView(ComponentsGallery())
        },
    ]
}

private struct ComponentsGallery: View {
    @State private var selectedDays: Set<Weekday> = [.monday, .tuesday, .thursday, .friday]
    @State private var expanded = false
    @State private var chip: String?
    @State private var tab = AppRouter.Tab.today
    @State private var pickedColor = StreakColor.teal
    @State private var pickedIcon = "leaf.fill"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                group("Tab bar (tap to switch)") {
                    AppTabBar(selection: $tab)
                }
                group("Week strip · every day state") {
                    WeekStrip(days: Self.sampleWeek)
                }
                group("Every streak icon on a badge (20pt)") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 6), spacing: Spacing.xs) {
                        ForEach(Array(StreakIcon.all.enumerated()), id: \.element) { index, icon in
                            IconBadge(icon: icon, color: StreakColor.allCases[index % StreakColor.allCases.count])
                        }
                    }
                    IconBadge(icon: "music.note", color: .coral, onHero: true)
                        .padding(Spacing.sm)
                        .background(StreakColor.coral.main, in: .rounded(Radius.lg))
                }
                group("Icon badges · every color") {
                    HStack(spacing: Spacing.xs) {
                        ForEach(StreakColor.allCases) { color in
                            IconBadge(icon: StreakIcon.all[StreakColor.allCases.firstIndex(of: color)! * 3], color: color)
                        }
                    }
                }
                group("Hero cards · four colors") {
                    ForEach([StreakColor.coral, .green, .blue, .purple], id: \.self) { color in
                        TaskCard(task: Self.hero(color), now: SampleData.today, onOpen: {}, onCheckIn: {})
                    }
                }
                group("Color and icon picker") {
                    StreakStylePicker(color: $pickedColor, icon: $pickedIcon)
                }
                group("Task cards") {
                    TaskCard(task: SampleData.gym, now: SampleData.today, onOpen: {}, onCheckIn: {})
                    TaskCard(task: SampleData.gym, now: SampleData.closingSoon, onOpen: {}, onCheckIn: {})
                    TaskCard(task: SampleData.gym.checkedIn(at: SampleData.time(18, 42)), now: SampleData.today,
                             onOpen: {}, onCheckIn: {})
                    TaskCard(task: SampleData.journal, now: SampleData.today, onOpen: {}, onCheckIn: {})
                }
                group("Chunky buttons · press and hold to see the press-down") {
                    ChunkyButton("Check in", systemImage: "camera.fill") {}
                    ChunkyButton(style: .success, "Submit") {}
                    ChunkyButton(style: .secondary, "Use a skip") {}
                    ChunkyButton(style: .danger, "Use skip") {}
                    ChunkyButton("Opens 6:00 PM") {}.disabled(true)
                    ChunkyButton(style: .white(label: StreakColor.coral.main), "Check in", systemImage: "camera.fill") {}
                        .padding(Spacing.md)
                        .chunkyCard(fill: StreakColor.coral.main, lip: StreakColor.coral.lip, outline: nil)
                }
                group("Chunky card · tappable") {
                    Button {} label: {
                        Text("Press me").font(Font.app.cardTitle).foregroundStyle(Color.app.textPrimary)
                            .frame(maxWidth: .infinity).padding(Spacing.md)
                    }
                    .buttonStyle(ChunkyCardButtonStyle())
                }
                group("Progress bars") {
                    ProgressBar(progress: 0.15)
                    ProgressBar(progress: 0.6, color: Color.app.success)
                    ProgressBar(progress: 1, color: Color.app.gold)
                }
                group("Sounds (play with Sounds on)") {
                    ForEach(SoundPlayer.Sound.allCases, id: \.self) { sound in
                        ChunkyButton(style: .secondary, "Play \(sound.rawValue)", systemImage: "speaker.wave.2.fill") {
                            SoundPlayer.shared.play(sound, enabled: true)
                        }
                    }
                }
                group("Status pills") {
                    // Stacked rather than side by side, so the page fits at the largest text sizes.
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        StatusPill(kind: .open)
                        StatusPill(kind: .done("7:42 AM"))
                        StatusPill(kind: .upcoming("9:00 PM"))
                        StatusPill(kind: .skipped)
                        StatusPill(kind: .missed)
                    }
                }
                group("Streak labels") {
                    StreakLabel(streak: Streak(weeks: 3, days: 2, totalCheckIns: 14))
                    StreakLabel(streak: Streak(weeks: 3, days: 2, totalCheckIns: 14), style: .long)
                    StreakLabel(streak: .zero)
                    StreakLabel(streak: .zero, style: .long)
                }
                group("Stat tiles") {
                    HStack(spacing: Spacing.sm) {
                        StatTile(label: "Streak", value: "3w 2d")
                        StatTile(label: "Skips left this week", value: "1 of 1")
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                group("Week day circles") {
                    HStack(spacing: 0) {
                        WeekDayCircle(day: .monday, status: .done).frame(maxWidth: .infinity)
                        WeekDayCircle(day: .tuesday, status: .skipped).frame(maxWidth: .infinity)
                        WeekDayCircle(day: .wednesday, status: .missed).frame(maxWidth: .infinity)
                        WeekDayCircle(day: .thursday, status: .today).frame(maxWidth: .infinity)
                        WeekDayCircle(day: .friday, status: .upcoming).frame(maxWidth: .infinity)
                    }
                }
                group("Day chips") {
                    HStack(spacing: 0) {
                        ForEach(Weekday.allCases) { day in
                            DayChip(day: day, isSelected: selectedDays.contains(day)) {
                                if selectedDays.contains(day) { selectedDays.remove(day) } else { selectedDays.insert(day) }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                group("Photo thumbnails") {
                    HStack(spacing: Spacing.xs) {
                        ForEach(0..<4, id: \.self) { _ in PhotoThumbnail() }
                    }
                }
                group("Filter chips") {
                    HStack(spacing: Spacing.xs) {
                        FilterChip(title: "All", isSelected: chip == nil) { chip = nil }
                        FilterChip(title: "Gym", isSelected: chip == "gym") { chip = "gym" }
                        FilterChip(title: "Guitar", isSelected: chip == "guitar") { chip = "guitar" }
                    }
                }
                group("Disclosure row") {
                    DisclosureRow(label: "Done today", count: 2, isExpanded: $expanded)
                }
                group("Habit rows") {
                    ForEach([SampleData.gym, SampleData.climbing, SampleData.meditation]) { task in
                        Button {} label: { HabitRow(task: task) }.buttonStyle(ChunkyCardButtonStyle())
                    }
                }
                group("Empty state") {
                    EmptyStateView {}
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.app.background)
        .navigationTitle("Components")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Mon full, Tue partly done, Wed nothing scheduled, Thu today, Fri–Sun still to come.
    private static let sampleWeek: [WeekStripDay] = {
        let monday = Calendar.current.date(byAdding: .day, value: -3, to: Calendar.current.startOfDay(for: SampleData.today))!
        func day(_ weekday: Weekday, _ kind: WeekStripDay.Kind, _ done: Int, _ total: Int) -> WeekStripDay {
            WeekStripDay(weekday: weekday,
                         date: Calendar.current.date(byAdding: .day, value: weekday.rawValue - 1, to: monday)!,
                         kind: kind, done: done, total: total)
        }
        return [day(.monday, .past, 3, 3), day(.tuesday, .past, 1, 3), day(.wednesday, .plain, 0, 0),
                day(.thursday, .today, 1, 4), day(.friday, .plain, 0, 0), day(.saturday, .plain, 0, 0),
                day(.sunday, .plain, 0, 0)]
    }()

    /// The open Gym task, recolored.
    private static func hero(_ color: StreakColor) -> TaskSnapshot {
        var task = SampleData.gym
        task.color = color
        return task
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(Font.app.sectionHeader)
                .foregroundStyle(Color.app.textTertiary)
                .padding(.top, Spacing.md)
            content()
        }
    }
}
#endif
