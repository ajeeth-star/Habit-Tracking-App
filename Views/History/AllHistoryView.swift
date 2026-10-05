import SwiftUI

/// Where History opens: a day tapped in Today's week strip, so it scrolls straight to that day.
struct HistoryFocus: Hashable {
    /// Start of the tapped day.
    var day: Date
    /// Nothing was scheduled that day (the empty header then says "Nothing scheduled", not "No check-ins").
    var nothingScheduled: Bool
}

/// History (design.md §4.12): every check-in across streaks, grouped by day, with filter chips for one
/// streak at a time. Skips and misses show as small text rows. Pushed from Today with a standard
/// navigation bar and back button; must sit inside a `NavigationStack`.
struct AllHistoryView: View {
    @Environment(TaskStore.self) private var store
    /// Nil means "All".
    @State private var filter: String?
    @State private var openedPhoto: HistoryEvent?
    /// Opened from a tapped day: scroll there first.
    var focus: HistoryFocus?

    private let format = Formatters.current

    init(filter: String? = nil, focus: HistoryFocus? = nil) {
        _filter = State(initialValue: filter)
        self.focus = focus
    }

    var body: some View {
        let now = store.now()
        let days = daysShown(now: now)
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !chipTasks.isEmpty {
                        chips
                    }

                    if days.isEmpty {
                        Text(Strings.History.empty)
                            .font(Font.app.subhead)
                            .foregroundStyle(Color.app.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, Spacing.xxxl)
                            .padding(.horizontal, Spacing.lg)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(days, id: \.date) { day in
                                dayHeader(day.date, now: now)
                                    .id(day.date)
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    if day.events.isEmpty {
                                        Text(focus?.nothingScheduled == true
                                             ? Strings.History.nothingScheduled : Strings.History.noCheckIns)
                                            .font(Font.app.meta)
                                            .foregroundStyle(Color.app.textTertiary)
                                    }
                                    ForEach(day.events) { row($0) }
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    }
                }
                .padding(.bottom, Spacing.xl)
            }
            .onAppear {
                guard let focus else { return }
                // Wait a moment so the push finishes and the rows exist, then jump to the day.
                DispatchQueue.main.async {
                    proxy.scrollTo(focus.day, anchor: .top)
                }
            }
        }
        .background(Color.app.background)
        .navigationTitle(Strings.AllHistory.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(Color.app.background, for: .navigationBar)
        .fullScreenCover(item: $openedPhoto) { event in
            PhotoViewer(date: event.date) { openedPhoto = nil }
        }
    }

    /// The timeline, plus an empty section for the focused day if it has nothing in it.
    private func daysShown(now: Date) -> [HistoryTimeline.Day] {
        var days = HistoryTimeline.days(for: filteredTasks, now: now)
        if let focus, !days.contains(where: { $0.date == focus.day }) {
            days.append(HistoryTimeline.Day(date: focus.day, events: []))
            days.sort { $0.date > $1.date }
        }
        return days
    }

    private func dayHeader(_ date: Date, now: Date) -> some View {
        Text(format.historyDay(date, now: now))
            .font(Font.app.sectionHeader)
            .foregroundStyle(Color.app.textTertiary)
            .accessibilityAddTraits(.isHeader)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xs)
    }

    // MARK: Filter

    /// Habits with anything in their history, in Habits tab order (active by streak, then archived).
    private var chipTasks: [TaskSnapshot] {
        (store.activeByStreak + store.archived).filter { task in
            !task.checkIns.isEmpty || task.week.contains { $0.status == .skipped || $0.status == .missed }
        }
    }

    private var filteredTasks: [TaskSnapshot] {
        guard let filter else { return store.tasks }
        return store.tasks.filter { $0.id == filter }
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                FilterChip(title: Strings.AllHistory.all, isSelected: filter == nil) { filter = nil }
                ForEach(chipTasks) { task in
                    FilterChip(title: task.name, isSelected: filter == task.id, selectedFill: task.color.solid) {
                        filter = task.id
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: Rows

    @ViewBuilder private func row(_ event: HistoryEvent) -> some View {
        switch event.kind {
        case .checkIn:
            Button { openedPhoto = event } label: {
                HStack(spacing: Spacing.sm) {
                    if let task = store.task(event.taskID) {
                        IconBadge(task: task)
                    }
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(event.taskName)
                            .font(Font.app.cardTitle)
                            .foregroundStyle(Color.app.textPrimary)
                        Text(format.time(of: event.date))
                            .font(Font.app.meta)
                            .monospacedDigit()
                            .foregroundStyle(Color.app.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    PhotoThumbnail()
                        .frame(width: Sizes.historyThumbnail, height: Sizes.historyThumbnail)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
        case .skip:
            note(event, icon: "minus", color: Color.app.textSecondary)
        case .miss:
            note(event, icon: "xmark", color: Color.app.danger)
        }
    }

    private func note(_ event: HistoryEvent, icon: String, color: Color) -> some View {
        Label {
            Text(format.historyNote(event))
        } icon: {
            Image(systemName: icon)
        }
        .font(Font.app.meta)
        .foregroundStyle(color)
        .accessibilityElement(children: .combine)
    }
}
