#if DEBUG
import SwiftUI

/// Developer tool, DEBUG builds only: every screen in every state, filled with `SampleData`,
/// so the designs can be checked in the simulator (VS Code can't show SwiftUI previews).
/// This file isn't compiled into Release builds.
struct DesignGalleryView: View {
    /// Opens this entry straight away (used by the `-galleryEntry <id>` launch argument).
    var initialEntryID: String?

    @Environment(\.dismiss) private var dismiss
    @Environment(StreakDisplaySettings.self) private var settings
    @State private var appearance = Appearance.system
    @State private var path: [String] = []
    @State private var presented: GalleryEntry?
    @State private var didOpenInitial = false

    enum Appearance: String, CaseIterable, Identifiable {
        case system = "System", light = "Light", dark = "Dark"
        var id: Self { self }
        var scheme: ColorScheme? {
            switch self {
            case .system: nil
            case .light: .light
            case .dark: .dark
            }
        }
    }

    var body: some View {
        @Bindable var settings = settings
        NavigationStack(path: $path) {
            List {
                Section {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(Appearance.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Streaks", selection: $settings.mode) {
                        Text("Weeks + days").tag(StreakDisplayMode.weeksAndDays)
                        Text("Days only").tag(StreakDisplayMode.daysOnly)
                    }
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
        .sheet(item: sheetBinding) { entry in
            entry.content { presented = nil }
                .preferredColorScheme(appearance.scheme)
        }
        .fullScreenCover(item: coverBinding) { entry in
            entry.content { presented = nil }
                .preferredColorScheme(appearance.scheme)
        }
        .preferredColorScheme(appearance.scheme)
        .onAppear {
            guard !didOpenInitial, let id = initialEntryID,
                  let entry = GalleryEntry.all.first(where: { $0.id == id }) else { return }
            didOpenInitial = true
            open(entry)
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

    static let all: [GalleryEntry] = home + detail + form + skip + checkIn + history + components

    // MARK: Entries

    private static let home: [GalleryEntry] = [
        GalleryEntry(id: "home.all", section: "Home", title: "Every card state") { close in
            AnyView(HomeView(tasks: SampleData.allTasks, date: SampleData.today, onOpenGallery: close))
        },
        GalleryEntry(id: "home.empty", section: "Home", title: "Empty (first launch)") { close in
            AnyView(HomeView(tasks: [], date: SampleData.today, onOpenGallery: close))
        },
    ]

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
            AnyView(TaskDetailView(task: task))
        }
    }

    private static let form: [GalleryEntry] = [
        formEntry("create", "New task · empty", .create, nil),
        formEntry("filled", "New task · filled in", .create, TaskFormView.Draft(
            name: "Gym", days: [.monday, .tuesday, .thursday, .friday],
            window: TimeWindow(start: TimeOfDay(18), end: TimeOfDay(20)), skips: 1)),
        formEntry("allSkips", "New task · skips = days", .create, TaskFormView.Draft(
            name: "Guitar", days: [.wednesday, .saturday],
            window: TimeWindow(start: TimeOfDay(12), end: TimeOfDay(13)), skips: 2)),
        formEntry("invalid", "New task · end before start", .create, TaskFormView.Draft(
            name: "Run", days: [.tuesday],
            window: TimeWindow(start: TimeOfDay(19), end: TimeOfDay(17)), skips: 0)),
        formEntry("edit", "Edit · no changes", .edit(SampleData.gym), nil),
        formEntry("editPending", "Edit · next-week changes", .edit(SampleData.gym), TaskFormView.Draft(
            name: "Gym", days: [.monday, .tuesday, .wednesday, .thursday, .friday],
            window: SampleData.gym.window, skips: 2)),
    ]

    private static func formEntry(_ id: String, _ title: String, _ mode: TaskFormView.Mode,
                                  _ draft: TaskFormView.Draft?) -> GalleryEntry {
        GalleryEntry(id: "form.\(id)", section: "Create / edit task", title: title, presentation: .sheet) { _ in
            AnyView(TaskFormView(mode: mode, draft: draft))
        }
    }

    private static let skip: [GalleryEntry] = [
        skipEntry("lastOneDay", "Last skip · one day left after today", SampleData.skipLastOneDayLeft),
        skipEntry("lastSeveral", "Last skip · several days left", SampleData.skipLastSeveralDaysLeft),
        skipEntry("lastNone", "Last skip · last day of the week", SampleData.skipLastNoDaysLeft),
        skipEntry("notLast", "Not the last skip", SampleData.skipNotLast),
    ]

    private static func skipEntry(_ id: String, _ title: String, _ prompt: SkipPrompt) -> GalleryEntry {
        GalleryEntry(id: "skip.\(id)", section: "Skip dialog", title: title, presentation: .cover) { close in
            AnyView(ZStack {
                NavigationStack { TaskDetailView(task: SampleData.gym) }
                SkipConfirmationView(prompt: prompt)
            })
        }
    }

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
        successEntry("midWeek", "Success · 1 more this week", SampleData.successMidWeek),
        successEntry("twoLeft", "Success · 2 more this week", SampleData.successTwoLeft),
        successEntry("complete", "Success · week complete", SampleData.successWeekComplete),
        successEntry("refund", "Success · skip given back", SampleData.successSkipRefunded),
        GalleryEntry(id: "flow", section: "Check-in", title: "Whole flow (tap through)", presentation: .cover) { _ in
            AnyView(CheckInFlowView(task: SampleData.gym))
        },
    ]

    private static func successEntry(_ id: String, _ title: String, _ result: CheckInResult) -> GalleryEntry {
        GalleryEntry(id: "success.\(id)", section: "Check-in", title: title, presentation: .cover) { close in
            AnyView(CheckInSuccessView(result: result, onDone: close))
        }
    }

    private static let history: [GalleryEntry] = [
        GalleryEntry(id: "history.photos", section: "History", title: "With photos") { _ in
            AnyView(HistoryView(task: SampleData.skincare))
        },
        GalleryEntry(id: "history.empty", section: "History", title: "Empty") { _ in
            AnyView(HistoryView(task: SampleData.reading))
        },
    ]

    private static let components: [GalleryEntry] = [
        GalleryEntry(id: "components", section: "Components", title: "All components") { _ in
            AnyView(ComponentsGallery())
        },
    ]
}

/// Every component in each of its states, on one scrolling page.
private struct ComponentsGallery: View {
    @State private var selectedDays: Set<Weekday> = [.monday, .tuesday, .thursday, .friday]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                group("Buttons") {
                    PrimaryButton("Check in", systemImage: "camera.fill") {}
                    PrimaryButton("Opens 6:00 PM") {}.disabled(true)
                    SecondaryButton("Use a skip") {}
                    SecondaryButton("No skips left") {}.disabled(true)
                    DangerTextButton("Use skip") {}
                }
                group("Status pills") {
                    HStack(spacing: Spacing.xs) {
                        StatusPill(kind: .open)
                        StatusPill(kind: .done)
                        StatusPill(kind: .upcoming("9:00 PM"))
                    }
                    HStack(spacing: Spacing.xs) {
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
