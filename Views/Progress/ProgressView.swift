import SwiftUI

/// The Progress tab (design.md §4.19): a month calendar, this month's stats, each streak's last 30 days, and the
/// best weekday, all calculated from the saved records. History is pushed from here. Must sit inside a
/// `NavigationStack`. (Named `ProgressTabView` so it doesn't hide SwiftUI's own `ProgressView`.)
struct ProgressTabView: View {
    @Environment(TaskStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 0 is this month, -1 last month, and so on.
    @State private var monthOffset: Int
    @State private var history: HistoryRoute?
    /// Off while the tab is hidden, on once it appears: the stat numbers count up from 0.
    @State private var counting = false

    private struct HistoryRoute: Hashable, Identifiable {
        var focus: HistoryFocus?
        var id: Self { self }
    }

    init(monthOffset: Int = 0) {
        _monthOffset = State(initialValue: monthOffset)
    }

    var body: some View {
        TimelineView(.everyMinute) { context in
            content(stats: ProgressStats(tasks: store.tasks, now: store.now(at: context.date)))
        }
        .background(Color.app.background)
        .navigationTitle(Strings.Progress.title)
        .toolbar(.hidden, for: .navigationBar)
        .statusBarBackdrop()
        .navigationDestination(item: $history) { route in
            AllHistoryView(focus: route.focus)
        }
        // History is a page of its own: the tab bar slides away while it's open.
        .onChange(of: history) { _, route in
            router.hidesTabBar = route != nil
        }
        .onAppear {
            guard !reduceMotion else { counting = true; return }
            withAnimation(Motion.settle.delay(Motion.countUpDelay)) { counting = true }
        }
        .onDisappear { counting = false }
    }

    private func content(stats: ProgressStats) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                if stats.isEmpty {
                    emptyState
                        .padding(.top, Spacing.xxl)
                } else {
                    filled(stats: stats)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
    }

    private var header: some View {
        HStack {
            Text(Strings.Progress.title)
                .font(Font.app.screenTitle)
                .foregroundStyle(Color.app.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if !store.tasks.isEmpty {
                Button { history = HistoryRoute() } label: {
                    HStack(spacing: Spacing.xxs) {
                        Text(Strings.Progress.viewAllPhotos)
                        Image(systemName: "chevron.right")
                    }
                    .font(Font.app.meta)
                    .foregroundStyle(Color.app.flame)
                    .frame(minHeight: Sizes.tapTarget)
                    .contentShape(Rectangle())
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Strings.Progress.viewAllPhotos)
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("progress.history")
            }
        }
        .padding(.top, Spacing.xs)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            FlameCharacterView(form: .ember, mood: .happy, size: Sizes.flameEmpty)
            SpeechBubble(text: Strings.Progress.empty, centered: true)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private func filled(stats: ProgressStats) -> some View {
        let range = stats.monthRange
        let month = stats.month(offset: monthOffset)
        monthSwitcher(month: month.start, range: range)
            .padding(.top, Spacing.xs)
        MonthCalendar(month: month) { day in
            history = HistoryRoute(focus: HistoryFocus(day: day.date, nothingScheduled: day.total == 0))
        }
        .padding(Spacing.md)
        .chunkyCard()
        .padding(.top, Spacing.md)
        .appearSlideIn(index: 0)

        sectionHeader(Strings.Progress.thisMonth)
        monthStats(month.stats)
            .appearSlideIn(index: 1)

        let rates = stats.recentRates(order: store.activeByStreak)
        if !rates.isEmpty {
            HStack(alignment: .firstTextBaseline) {
                sectionHeader(Strings.Progress.yourStreaks)
                Spacer()
                Text(Strings.Progress.lastThirtyDays)
                    .font(Font.app.caption)
                    .foregroundStyle(Color.app.textTertiary)
            }
            VStack(spacing: Spacing.sm) {
                ForEach(Array(rates.enumerated()), id: \.element.task.id) { index, item in
                    StreakRateRow(task: item.task, rate: item.rate)
                        .appearSlideIn(index: 2 + index)
                }
            }
        }

        if let best = stats.bestDay {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Color.app.gold)
                Text(Formatters.current.bestDay(best))
                    .foregroundStyle(Color.app.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(Font.app.subhead)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("progress.bestDay")
            .padding(.top, Spacing.xl)
        }
    }

    /// "‹ November 2026 ›", limited to the first streak's month and this month.
    private func monthSwitcher(month: Date, range: ClosedRange<Date>) -> some View {
        HStack {
            monthButton("chevron.left", Strings.Progress.previousMonth, enabled: month > range.lowerBound) {
                monthOffset -= 1
            }
            Text(Formatters.current.monthHeader(month))
                .font(Font.app.cardTitle)
                .foregroundStyle(Color.app.textPrimary)
                .frame(maxWidth: .infinity)
                .contentTransition(.opacity)
                .accessibilityIdentifier("progress.month")
            monthButton("chevron.right", Strings.Progress.nextMonth, enabled: month < range.upperBound) {
                monthOffset += 1
            }
        }
    }

    private func monthButton(_ icon: String, _ label: String, enabled: Bool,
                             action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : Motion.standard) { action() }
        } label: {
            Image(systemName: icon)
                .font(Font.app.button)
                .foregroundStyle(enabled ? Color.app.flame : Color.app.textTertiary)
                .frame(width: Sizes.tapTarget, height: Sizes.tapTarget)
                .contentShape(Rectangle())
        }
        .disabled(!enabled)
        .accessibilityLabel(label)
        .accessibilityIdentifier(icon == "chevron.left" ? "progress.previousMonth" : "progress.nextMonth")
    }

    private func monthStats(_ stats: MonthStats) -> some View {
        let format = Formatters.current
        return Grid(horizontalSpacing: Spacing.sm, verticalSpacing: Spacing.sm) {
            GridRow {
                ProgressStatCard(icon: "camera.fill", color: Color.app.info, label: Strings.Progress.checkIns,
                                 value: stats.checkIns, counting: counting)
                ProgressStatCard(icon: "checkmark.circle.fill", color: Color.app.success,
                                 label: Strings.Progress.completionRate,
                                 value: stats.completionRate.map(format.percentValue),
                                 text: Strings.Progress.percent, counting: counting)
            }
            GridRow {
                ProgressStatCard(icon: "star.fill", color: Color.app.gold, label: Strings.Progress.perfectDays,
                                 value: stats.perfectDays, counting: counting)
                ProgressStatCard(icon: "flame.fill", color: Color.app.flame, label: Strings.Progress.longestDayStreak,
                                 value: stats.longestDayStreak, counting: counting)
            }
        }
        .accessibilityIdentifier("progress.stats")
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Font.app.sectionHeader)
            .foregroundStyle(Color.app.textTertiary)
            .accessibilityAddTraits(.isHeader)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xs)
    }
}

/// One streak's last 30 days: its badge, name, a candy bar in its color, and the percentage.
private struct StreakRateRow: View {
    let task: TaskSnapshot
    let rate: Double?

    var body: some View {
        let text = Formatters.current.rate(rate)
        HStack(spacing: Spacing.sm) {
            IconBadge(task: task)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(task.name)
                    .font(Font.app.cardTitle)
                    .foregroundStyle(Color.app.textPrimary)
                    .lineLimit(2)
                ProgressBar(progress: rate ?? 0, color: task.color.main)
            }
            Text(text)
                .font(Font.app.cardStreak)
                .foregroundStyle(Color.app.textPrimary)
                .frame(minWidth: Sizes.tapTarget, alignment: .trailing)
        }
        .padding(Spacing.md)
        .chunkyCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Progress.streakRate(task.name, text))
    }
}
