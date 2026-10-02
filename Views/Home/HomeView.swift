import SwiftUI

/// The Today tab (design.md §4.1–4.2): today's summary, what's still ahead today, a collapsible
/// "Done today" row, and "Coming up". Must sit inside a `NavigationStack`. Reads the shared `TaskStore`.
struct HomeView: View {
    @Environment(TaskStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Kept for as long as the app is open (the tab stays alive while you switch tabs).
    @State private var showsDone: Bool
    @State private var openedTaskID: String?
    @State private var checkInTask: TaskSnapshot?
    /// Set on Submit, applied once the celebration closes, so the hero card closes in front of you.
    @State private var pendingCheckIn: TaskSnapshot?
    @State private var showingCreate = false

    init(showsDone: Bool = false) {
        _showsDone = State(initialValue: showsDone)
    }

    var body: some View {
        TimelineView(.everyMinute) { context in
            content(now: store.now(at: context.date))
        }
        .background(Color.app.background)
        .toolbar(.hidden, for: .navigationBar)
        .statusBarBackdrop()
        .navigationDestination(item: $openedTaskID) { id in
            if let task = store.binding(for: id) {
                TaskDetailView(task: task, now: store.now()) { removal in
                    switch removal {
                    case .archive: store.archive(id)
                    case .delete: store.delete(id)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            TaskFormView(mode: .create)
        }
        .fullScreenCover(item: $checkInTask, onDismiss: applyPendingCheckIn) { task in
            CheckInFlowView(task: task, now: store.now()) { pendingCheckIn = $0 }
        }
    }

    private func content(now: Date) -> some View {
        ScrollView {
            if store.active.isEmpty {
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
                    let summary = TodaySummary(tasks: store.active, now: now)
                    if summary.total > 0 {
                        TodaySummaryCard(summary: summary)
                            .padding(.top, Spacing.md)
                    }
                    todaySection(now: now)
                    comingUpSection(now: now)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
        }
    }

    // MARK: Header

    private func header(now: Date) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                Text(Strings.Home.title)
                    .font(Font.app.screenTitle)
                    .foregroundStyle(Color.app.textPrimary)
                    .accessibilityAddTraits(.isHeader)
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
        .padding(.top, Spacing.xs)
    }

    // MARK: Today

    private var scheduledToday: [TaskSnapshot] {
        store.active.filter(\.isScheduledToday).sorted { $0.window.start < $1.window.start }
    }

    /// Still ahead today (open or upcoming), plus missed tasks so their "Streak ended" lines stay visible.
    private var aheadToday: [TaskSnapshot] {
        scheduledToday.filter {
            switch $0.cardState {
            case .open, .upcoming, .missed: true
            default: false
            }
        }
    }

    /// Checked in or skipped today: folded into the "Done today" row.
    private var doneToday: [TaskSnapshot] {
        scheduledToday.filter {
            switch $0.cardState {
            case .done, .skipped: true
            default: false
            }
        }
    }

    @ViewBuilder private func todaySection(now: Date) -> some View {
        if !scheduledToday.isEmpty {
            section(Strings.Home.todaySection) {
                ForEach(aheadToday) { card($0, now: now) }
                if !doneToday.isEmpty {
                    DisclosureRow(label: Strings.Today.doneToday, count: doneToday.count, isExpanded: $showsDone)
                    if showsDone {
                        ForEach(doneToday) { card($0, now: now) }
                    }
                }
            }
        }
    }

    private func card(_ task: TaskSnapshot, now: Date) -> some View {
        TaskCard(
            task: task,
            now: now,
            onOpen: { openedTaskID = task.id },
            onCheckIn: { checkInTask = task }
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: Coming up

    /// Tasks not scheduled today, soonest next window first.
    private func comingUp(now: Date) -> [(task: TaskSnapshot, daysAhead: Int)] {
        let today = Weekday(now)
        return store.active
            .filter { !$0.isScheduledToday }
            .compactMap { task in task.nextWindow(after: today).map { (task, $0.daysAhead) } }
            .sorted { ($0.daysAhead, $0.task.window.start.minutesSinceMidnight)
                < ($1.daysAhead, $1.task.window.start.minutesSinceMidnight) }
    }

    @ViewBuilder private func comingUpSection(now: Date) -> some View {
        let items = comingUp(now: now)
        if !items.isEmpty {
            section(Strings.Today.comingUp) {
                ForEach(items, id: \.task.id) { item in
                    ComingUpRow(task: item.task, daysAhead: item.daysAhead, today: Weekday(now)) {
                        openedTaskID = item.task.id
                    }
                }
            }
        }
    }

    /// A section header (`xl` above, `xs` below) over its cards, `sm` apart.
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(Font.app.sectionHeader)
                .foregroundStyle(Color.app.textTertiary)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.xs)
            VStack(alignment: .leading, spacing: Spacing.sm) {
                content()
            }
        }
    }

    // MARK: State

    /// After the celebration closes: the hero card closes into the "Done today" row and the ring fills.
    private func applyPendingCheckIn() {
        guard let updated = pendingCheckIn else { return }
        pendingCheckIn = nil
        withAnimation(reduceMotion ? nil : Motion.settle) {
            store.replace(updated)
        }
    }
}

/// A "Coming up" row: the task's name and its next window, e.g. "Guitar · Tomorrow, 9:00 PM".
private struct ComingUpRow: View {
    let task: TaskSnapshot
    let daysAhead: Int
    let today: Weekday
    let onOpen: () -> Void

    var body: some View {
        let next = Formatters.current.comingUp(
            daysAhead: daysAhead, weekday: weekdayOfNext, start: task.window.start)
        Button(action: onOpen) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text(task.name)
                    .font(Font.app.cardTitle)
                    .foregroundStyle(Color.app.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(next)
                    .font(Font.app.meta)
                    .monospacedDigit()
                    .foregroundStyle(Color.app.textSecondary)
                    .multilineTextAlignment(.trailing)
            }
            .padding(Spacing.md)
            .background(Color.app.surface, in: .rounded(Radius.lg))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .strokeBorder(Color.app.separator, lineWidth: Sizes.hairline)
            }
            .contentShape(.rounded(Radius.lg))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(task.name + Strings.separator + next)
        .accessibilityAddTraits(.isButton)
    }

    private var weekdayOfNext: Weekday {
        Weekday(rawValue: (today.rawValue - 1 + daysAhead) % 7 + 1) ?? today
    }
}
