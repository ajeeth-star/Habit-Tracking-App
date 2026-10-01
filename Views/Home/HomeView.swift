import SwiftUI

/// The hub: today's tasks, then the rest (design.md §4.1–4.2). Must sit inside a `NavigationStack`.
struct HomeView: View {
    let tasks: [TaskSnapshot]
    let date: Date
    /// Opens the Design Gallery. The paintbrush button only exists in DEBUG builds.
    var onOpenGallery: (() -> Void)?

    @State private var openedTask: TaskSnapshot?
    @State private var checkInTask: TaskSnapshot?
    @State private var showingCreate = false

    var body: some View {
        ScrollView {
            if tasks.isEmpty {
                // Header on top, the invitation centered in the space left over.
                VStack(alignment: .leading, spacing: 0) {
                    header
                    Spacer(minLength: Spacing.xl)
                    EmptyStateView { showingCreate = true }
                    Spacer(minLength: Spacing.xl)
                }
                .padding(.horizontal, Spacing.lg)
                .containerRelativeFrame(.vertical)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    sections
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
        }
        .background(Color.app.background)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $openedTask) { task in
            TaskDetailView(task: task)
        }
        .sheet(isPresented: $showingCreate) {
            TaskFormView(mode: .create)
        }
        .fullScreenCover(item: $checkInTask) { task in
            CheckInFlowView(task: task)
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            #if DEBUG
            if let onOpenGallery {
                Button(action: onOpenGallery) {
                    Image(systemName: "paintbrush")
                        .font(Font.app.body)
                        .foregroundStyle(Color.app.textTertiary)
                        .frame(width: Sizes.tapTarget, height: Sizes.tapTarget, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Design Gallery")
            }
            #endif

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(Strings.Home.title)
                        .font(Font.app.screenTitle)
                        .foregroundStyle(Color.app.textPrimary)
                    Text(Formatters.current.homeDate(date))
                        .font(Font.app.subhead)
                        .foregroundStyle(Color.app.textSecondary)
                }
                Spacer()
                Button { showingCreate = true } label: {
                    Image(systemName: "plus")
                        .font(Font.app.screenTitle)
                        .foregroundStyle(Color.app.accentText)
                        .frame(minWidth: Sizes.tapTarget, minHeight: Sizes.tapTarget)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Strings.Home.createTask)
            }
        }
        .padding(.top, Spacing.xs)
    }

    // MARK: Sections

    private var todayTasks: [TaskSnapshot] {
        tasks.filter(\.isScheduledToday).sorted { $0.window.start < $1.window.start }
    }

    /// Already in next-scheduled order in the sample data; real ordering comes with real dates.
    private var notTodayTasks: [TaskSnapshot] {
        tasks.filter { !$0.isScheduledToday }
    }

    @ViewBuilder private var sections: some View {
        if !todayTasks.isEmpty {
            section(Strings.Home.todaySection, todayTasks)
        }
        if !notTodayTasks.isEmpty {
            section(Strings.Home.notTodaySection, notTodayTasks)
        }
    }

    private func section(_ title: String, _ tasks: [TaskSnapshot]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(Font.app.sectionHeader)
                .foregroundStyle(Color.app.textTertiary)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.xs)
            VStack(spacing: Spacing.sm) {
                ForEach(tasks) { task in
                    TaskCard(
                        task: task,
                        onOpen: { openedTask = task },
                        onCheckIn: { checkInTask = task }
                    )
                }
            }
        }
    }
}
