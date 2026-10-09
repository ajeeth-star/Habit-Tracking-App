import SwiftUI

/// The Habits tab (design.md §4.10): every active habit by current streak, then a collapsible
/// "Archived" row. Must sit inside a `NavigationStack`.
struct HabitsView: View {
    @Environment(TaskStore.self) private var store
    /// Kept for as long as the app is open.
    @State private var showsArchived: Bool
    @State private var openedTaskID: String?
    @State private var showingCreate = false

    init(showsArchived: Bool = false) {
        _showsArchived = State(initialValue: showsArchived)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                if store.active.isEmpty {
                    EmptyStateView { showingCreate = true }
                        .padding(.vertical, Spacing.xxxl)
                } else {
                    sectionTitle(Strings.Habits.active)
                    VStack(spacing: Spacing.sm) {
                        ForEach(Array(store.activeByStreak.enumerated()), id: \.element.id) { index, task in
                            Button { openedTaskID = task.id } label: { HabitRow(task: task) }
                                .buttonStyle(ChunkyCardButtonStyle())
                                .appearSlideIn(index: index)
                        }
                    }
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
    }

    private var header: some View {
        HStack(alignment: .top) {
            Text(Strings.Habits.title)
                .font(Font.app.screenTitle)
                .foregroundStyle(Color.app.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button { showingCreate = true } label: {
                Image(systemName: "plus")
                    .font(Font.app.screenTitle)
                    .foregroundStyle(Color.app.flame)
                    .frame(minWidth: Sizes.tapTarget, minHeight: Sizes.tapTarget)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(Strings.Home.createTask)
        }
        .padding(.top, Spacing.xs)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(Font.app.sectionHeader)
            .foregroundStyle(Color.app.textTertiary)
            .accessibilityAddTraits(.isHeader)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xs)
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
            TaskDetailView(task: binding, now: store.now()) { removal in
                switch removal {
                case .archive: store.archive(id)
                case .delete: store.delete(id)
                }
            }
        }
    }
}
