import SwiftUI

/// The hub: today's summary, today's tasks, then the rest (design.md §4.1–4.2).
/// Must sit inside a `NavigationStack`. Holds the tasks in memory so a check-in shows up straight
/// away; nothing is saved in this phase.
struct HomeView: View {
    /// Opens the Design Gallery. The paintbrush button only exists in DEBUG builds.
    var onOpenGallery: (() -> Void)?

    @State private var tasks: [TaskSnapshot]
    /// The clock: `startNow` plus however long the screen has been open. Sample data fixes "now"
    /// for this phase; the countdown still ticks along from there every minute.
    private let startNow: Date
    @State private var openedAt = Date()

    @State private var openedTaskID: String?
    @State private var checkInTask: TaskSnapshot?
    /// Set on Submit, applied once the celebration closes, so the hero card closes in front of you.
    @State private var pendingCheckIn: TaskSnapshot?
    @State private var showingCreate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(tasks: [TaskSnapshot], now: Date, onOpenGallery: (() -> Void)? = nil) {
        _tasks = State(initialValue: tasks)
        startNow = now
        self.onOpenGallery = onOpenGallery
    }

    var body: some View {
        TimelineView(.everyMinute) { context in
            content(now: currentNow(at: context.date))
        }
        .background(Color.app.background)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $openedTaskID) { id in
            TaskDetailView(task: binding(for: id), now: currentNow(at: Date()))
        }
        .sheet(isPresented: $showingCreate) {
            TaskFormView(mode: .create)
        }
        .fullScreenCover(item: $checkInTask, onDismiss: applyPendingCheckIn) { task in
            CheckInFlowView(task: task, now: currentNow(at: Date())) { pendingCheckIn = $0 }
        }
    }

    private func content(now: Date) -> some View {
        ScrollView {
            if tasks.isEmpty {
                // Header on top, the invitation centered in the space left over.
                VStack(alignment: .leading, spacing: 0) {
                    header(now: now)
                    Spacer(minLength: Spacing.xl)
                    EmptyStateView { showingCreate = true }
                    Spacer(minLength: Spacing.xl)
                }
                .padding(.horizontal, Spacing.lg)
                .containerRelativeFrame(.vertical)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    header(now: now)
                    let summary = TodaySummary(tasks: tasks, now: now)
                    if summary.total > 0 {
                        TodaySummaryCard(summary: summary)
                            .padding(.top, Spacing.md)
                    }
                    sections(now: now)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
        }
    }

    // MARK: Header

    private func header(now: Date) -> some View {
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
                    Text(Formatters.current.homeDate(now))
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

    @ViewBuilder private func sections(now: Date) -> some View {
        if !todayTasks.isEmpty {
            section(Strings.Home.todaySection, todayTasks, now: now)
        }
        if !notTodayTasks.isEmpty {
            section(Strings.Home.notTodaySection, notTodayTasks, now: now)
        }
    }

    private func section(_ title: String, _ tasks: [TaskSnapshot], now: Date) -> some View {
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
                        now: now,
                        onOpen: { openedTaskID = task.id },
                        onCheckIn: { checkInTask = task }
                    )
                }
            }
        }
    }

    // MARK: State

    private func currentNow(at date: Date) -> Date {
        startNow.addingTimeInterval(max(0, date.timeIntervalSince(openedAt)))
    }

    private func binding(for id: String) -> Binding<TaskSnapshot> {
        Binding {
            tasks.first { $0.id == id } ?? SampleData.gym
        } set: { updated in
            if let index = tasks.firstIndex(where: { $0.id == id }) { tasks[index] = updated }
        }
    }

    /// After the celebration closes: the hero card closes into a done card and the ring fills.
    private func applyPendingCheckIn() {
        guard let updated = pendingCheckIn, let index = tasks.firstIndex(where: { $0.id == updated.id }) else { return }
        pendingCheckIn = nil
        withAnimation(reduceMotion ? nil : Motion.settle) {
            tasks[index] = updated
        }
    }
}
