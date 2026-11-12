import SwiftUI

/// The Streaks tab (design.md §4.10): the collection. Every active streak as a bright tile in a 2-column grid,
/// by current streak, with a "New streak" tile last, then a collapsible "Archived" row. Must sit inside a
/// `NavigationStack`.
struct HabitsView: View {
    @Environment(TaskStore.self) private var store
    /// Kept for as long as the app is open.
    @State private var showsArchived: Bool
    @State private var openedTaskID: String?
    @State private var showingCreate = false
    /// A "Popular streaks" chip was tapped: the create form opens filled in.
    @State private var creatingFrom: StreakPreset?

    init(showsArchived: Bool = false) {
        _showsArchived = State(initialValue: showsArchived)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                if store.active.isEmpty {
                    EmptyStateView(onPick: { creatingFrom = $0 }) { showingCreate = true }
                        .padding(.vertical, Spacing.xxxl)
                } else {
                    grid
                        .padding(.top, Spacing.lg)
                }
                if !store.archived.isEmpty {
                    DisclosureRow(label: Strings.Habits.archived, count: store.archived.count,
                                  isExpanded: $showsArchived)
                        .padding(.top, Spacing.xl)
                    if showsArchived {
                        ArchivedHabitsList { openedTaskID = $0 }
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.app.background)
        .toolbar(.hidden, for: .navigationBar)
        .statusBarBackdrop()
        .navigationDestination(item: $openedTaskID) { id in
            HabitDestination(id: id)
        }
        .sheet(isPresented: $showingCreate) {
            TaskFormView(mode: .create)
        }
        .sheet(item: $creatingFrom) { preset in
            TaskFormView(mode: .create, draft: preset.draft)
        }
    }

    /// "Streaks" and its summary line on the left, the round chunky + on the right.
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(Strings.Habits.title)
                    .font(Font.app.screenTitle)
                    .foregroundStyle(Color.app.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                if !store.active.isEmpty {
                    Text(Formatters.current.streaksSummary(active: store.active.count,
                                                           skipsLeft: store.active.reduce(0) { $0 + $1.skipsLeft }))
                        .font(Font.app.meta)
                        .foregroundStyle(Color.app.textSecondary)
                        .contentTransition(.numericText())
                        .accessibilityIdentifier("streaks.summary")
                }
            }
            Spacer()
            CircleIconButton(systemImage: "plus", color: Color.app.flame,
                             label: Strings.Home.createTask) { showingCreate = true }
        }
        .padding(.top, Spacing.xs)
    }

    /// Two columns of tiles, highest streak first, with "New streak" always last.
    private var grid: some View {
        let tasks = store.activeByStreak
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.sm), GridItem(.flexible(), spacing: Spacing.sm)],
                         spacing: Spacing.sm) {
            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                Button { openedTaskID = task.id } label: { StreakTile(task: task) }
                    .buttonStyle(StreakTileButtonStyle(color: task.color, dormant: task.streak.totalCheckIns == 0))
                    .appearPop(index: index)
            }
            NewStreakTile { showingCreate = true }
                .appearPop(index: tasks.count)
        }
    }

}

/// The archived habits as rows, `Spacing.sm` apart. Used by the Habits tab and Settings.
struct ArchivedHabitsList: View {
    @Environment(TaskStore.self) private var store
    let onOpen: (String) -> Void

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(store.archived) { task in
                Button { onOpen(task.id) } label: { HabitRow(task: task) }
                    .buttonStyle(ChunkyCardButtonStyle())
            }
        }
    }
}

/// Where tapping a habit leads: its task screen, or the archived habit screen.
struct HabitDestination: View {
    let id: String
    @Environment(TaskStore.self) private var store

    var body: some View {
        if let task = store.task(id), task.isArchived {
            ArchivedHabitView(task: task)
        } else if let binding = store.binding(for: id) {
            TaskDetailView(task: binding) { removal in
                switch removal {
                case .archive: store.archive(id)
                case .delete: store.delete(id)
                }
            }
        }
    }
}
