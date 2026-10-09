import SwiftUI

/// The Today tab (design.md §4.1–4.2): greeting, this week, one status line, the open streak's hero
/// card, the rest of today with a collapsible "Done today" row, and "Coming up". History is pushed from
/// here. Must sit inside a `NavigationStack`. Reads the shared `TaskStore`.
struct HomeView: View {
    @Environment(TaskStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Kept for as long as the app is open (the tab stays alive while you switch tabs).
    @State private var showsDone: Bool
    @State private var openedTaskID: String?
    @State private var history: HistoryRoute?
    @State private var checkInTask: TaskSnapshot?
    /// Set on Submit, applied once the celebration closes, so the hero card closes in front of you.
    @State private var pendingCheckIn: TaskSnapshot?
    @State private var showingCreate = false
    @State private var showingSettings = false

    /// History, opened from the "History" link (no focus) or a tapped past day.
    private struct HistoryRoute: Hashable, Identifiable {
        var focus: HistoryFocus?
        var id: Self { self }
    }

    init(showsDone: Bool = false) {
        _showsDone = State(initialValue: showsDone)
    }

    var body: some View {
        TimelineView(.everyMinute) { context in
            content(now: store.now(at: context.date))
        }
        .background(Color.app.background)
        // Hidden bar, but the title names the back button on pushed screens ("< Today").
        .navigationTitle(Strings.Home.title)
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
        .navigationDestination(item: $history) { route in
            AllHistoryView(focus: route.focus)
        }
        // History is a page of its own: the tab bar slides away while it's open.
        .onChange(of: history) { _, route in
            router.hidesTabBar = route != nil
        }
        .sheet(isPresented: $showingCreate) {
            TaskFormView(mode: .create)
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack { SettingsView(showsDone: true) }
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
                    thisWeekRow
                        .padding(.top, Spacing.md)
                    WeekStrip(days: WeekProgress.days(for: store.tasks, now: now)) { day in
                        history = HistoryRoute(focus: HistoryFocus(day: day.date, nothingScheduled: day.total == 0))
                    }
                    StatusLine(summary: TodaySummary(tasks: store.active, now: now))
                        .padding(.top, Spacing.sm)
                    heroCards(now: now)
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
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button { showingSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(Font.app.button)
                        .foregroundStyle(Color.app.textSecondary)
                        .frame(minWidth: Sizes.tapTarget, minHeight: Sizes.tapTarget, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Strings.Home.settings)
                Spacer()
                Button { showingCreate = true } label: {
                    Image(systemName: "plus")
                        .font(Font.app.screenTitle)
                        .foregroundStyle(Color.app.flame)
                        .frame(minWidth: Sizes.tapTarget, minHeight: Sizes.tapTarget, alignment: .trailing)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Strings.Home.createTask)
            }

            Text(Formatters.current.greeting(now, name: settings.greetingName))
                .font(Font.app.subhead)
                .foregroundStyle(Color.app.textSecondary)
            Text(Strings.Home.title)
                .font(Font.app.screenTitle)
                .foregroundStyle(Color.app.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(Formatters.current.homeDate(now))
                .font(Font.app.subhead)
                .foregroundStyle(Color.app.textSecondary)
        }
    }

    /// "This week" on the left, a "History" link on the right.
    private var thisWeekRow: some View {
        HStack {
            Text(Strings.ThisWeek.title)
                .font(Font.app.sectionHeader)
                .foregroundStyle(Color.app.textTertiary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button { history = HistoryRoute() } label: {
                HStack(spacing: Spacing.xxs) {
                    Text(Strings.ThisWeek.history)
                    Image(systemName: "chevron.right")
                }
                .font(Font.app.meta)
                .foregroundStyle(Color.app.flame)
                .frame(minHeight: Sizes.tapTarget)
                .contentShape(Rectangle())
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Strings.ThisWeek.history)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("today.history")
        }
    }

    // MARK: Today

    private var scheduledToday: [TaskSnapshot] {
        store.active.filter(\.isScheduledToday).sorted { $0.window.start < $1.window.start }
    }

    /// Open right now and not done: the hero card(s), right under the status line.
    private var openToday: [TaskSnapshot] {
        scheduledToday.filter { $0.cardState == .open }
    }

    /// The rest of today still ahead, plus missed tasks so their "Streak ended" lines stay visible.
    private var aheadToday: [TaskSnapshot] {
        scheduledToday.filter {
            switch $0.cardState {
            case .upcoming, .missed: true
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

    @ViewBuilder private func heroCards(now: Date) -> some View {
        if !openToday.isEmpty {
            VStack(spacing: Spacing.sm) {
                ForEach(Array(openToday.enumerated()), id: \.element.id) { index, task in
                    card(task, now: now).appearSlideIn(index: index)
                }
            }
            .padding(.top, Spacing.md)
        }
    }

    @ViewBuilder private func todaySection(now: Date) -> some View {
        if !aheadToday.isEmpty || !doneToday.isEmpty {
            section(Strings.Home.laterToday) {
                ForEach(Array(aheadToday.enumerated()), id: \.element.id) { index, task in
                    card(task, now: now).appearSlideIn(index: openToday.count + index)
                }
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
                ForEach(Array(items.enumerated()), id: \.element.task.id) { index, item in
                    ComingUpRow(task: item.task, daysAhead: item.daysAhead, today: Weekday(now)) {
                        openedTaskID = item.task.id
                    }
                    .appearSlideIn(index: openToday.count + aheadToday.count + 1 + index)
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
            HStack(spacing: Spacing.sm) {
                IconBadge(task: task)
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
        }
        .buttonStyle(ChunkyCardButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(task.name + Strings.separator + next)
        .accessibilityAddTraits(.isButton)
    }

    private var weekdayOfNext: Weekday {
        Weekday(rawValue: (today.rawValue - 1 + daysAhead) % 7 + 1) ?? today
    }
}

/// Today's one-line status (design.md §4.1): "2 of 3 done today · Next: Gym at 6:00 PM",
/// "All done for today · …" with a checkmark, or "Rest day · …" with a moon.
private struct StatusLine: View {
    let summary: TodaySummary

    var body: some View {
        let parts = Formatters.current.statusLine(summary)
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            if summary.isRestDay {
                Image(systemName: "moon.fill")
                    .foregroundStyle(Color.app.textTertiary)
            } else if summary.isAllDone {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.app.success)
            }
            (Text(parts.emphasis ?? "").font(Font.app.statusCount).foregroundStyle(Color.app.textPrimary)
                + Text(parts.rest).foregroundStyle(Color.app.textSecondary))
                .monospacedDigit()
                .contentTransition(.numericText())
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(Font.app.subhead)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Formatters.current.statusText(summary))
        .accessibilityIdentifier("today.status")
    }
}
