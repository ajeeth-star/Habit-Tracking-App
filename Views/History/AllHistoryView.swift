import SwiftUI

/// The History tab (design.md §4.12): every check-in across habits, grouped by day, with filter chips
/// for one habit at a time. Skips and misses show as small text rows. Must sit inside a `NavigationStack`.
struct AllHistoryView: View {
    @Environment(TaskStore.self) private var store
    /// Nil means "All".
    @State private var filter: String?
    @State private var openedPhoto: HistoryEvent?

    private let format = Formatters.current

    init(filter: String? = nil) {
        _filter = State(initialValue: filter)
    }

    var body: some View {
        let now = store.now()
        let days = HistoryTimeline.days(for: filteredTasks, now: now)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(Strings.AllHistory.title)
                    .font(Font.app.screenTitle)
                    .foregroundStyle(Color.app.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, Spacing.xs)
                    .padding(.horizontal, Spacing.lg)

                if !chipTasks.isEmpty {
                    chips.padding(.top, Spacing.md)
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
                            Text(format.historyDay(day.date, now: now))
                                .font(Font.app.sectionHeader)
                                .foregroundStyle(Color.app.textTertiary)
                                .accessibilityAddTraits(.isHeader)
                                .padding(.top, Spacing.xl)
                                .padding(.bottom, Spacing.xs)
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                ForEach(day.events) { row($0) }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }
            }
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.app.background)
        .toolbar(.hidden, for: .navigationBar)
        .statusBarBackdrop()
        .fullScreenCover(item: $openedPhoto) { event in
            PhotoViewer(date: event.date) { openedPhoto = nil }
        }
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
                    FilterChip(title: task.name, isSelected: filter == task.id) { filter = task.id }
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
                    PhotoThumbnail()
                        .frame(width: Sizes.historyThumbnail, height: Sizes.historyThumbnail)
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
