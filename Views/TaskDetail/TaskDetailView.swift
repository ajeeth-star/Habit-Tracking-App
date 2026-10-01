import SwiftUI

/// One task: streak, skips, this week, actions, and recent photos (design.md §4.4).
struct TaskDetailView: View {
    let task: TaskSnapshot

    @Environment(\.dismiss) private var dismiss
    @Environment(StreakDisplaySettings.self) private var settings
    @State private var showingEdit = false
    @State private var showingHistory = false
    @State private var showingCheckIn = false
    @State private var showingSkip = false

    private let format = Formatters.current

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                stats.padding(.top, Spacing.md)
                thisWeek.padding(.top, Spacing.xl)
                actions.padding(.top, Spacing.xl)
                recentCheckIns.padding(.top, Spacing.xl)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.app.background)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(Font.app.button)
                        .foregroundStyle(Color.app.accentText)
                        .frame(minWidth: Sizes.tapTarget, minHeight: Sizes.tapTarget, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Strings.Detail.back)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingEdit = true } label: {
                    Text(Strings.Detail.edit)
                        .font(Font.app.body)
                        .foregroundStyle(Color.app.accentText)
                        .frame(minWidth: Sizes.tapTarget, minHeight: Sizes.tapTarget, alignment: .trailing)
                        .contentShape(Rectangle())
                }
            }
        }
        .navigationDestination(isPresented: $showingHistory) {
            HistoryView(task: task)
        }
        .sheet(isPresented: $showingEdit) {
            TaskFormView(mode: .edit(task))
        }
        .fullScreenCover(isPresented: $showingCheckIn) {
            CheckInFlowView(task: task)
        }
        .fullScreenCover(isPresented: $showingSkip) {
            SkipConfirmationView(prompt: task.skipPrompt)
                .presentationBackground(.clear)
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(task.name)
                .font(Font.app.screenTitle)
                .foregroundStyle(Color.app.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(format.schedule(days: task.days, window: task.window))
                .font(Font.app.meta)
                .foregroundStyle(Color.app.textSecondary)
        }
    }

    private var stats: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            AdaptiveStack(spacing: Spacing.sm) {
                // Tapping the streak switches weeks + days ↔ days only, app-wide (open: where this toggle lives).
                Button { settings.toggle() } label: {
                    StatTile(label: Strings.Detail.streak) {
                        Text(StreakLabel.string(task.streak, style: .short, mode: settings.mode))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityHint(Strings.Detail.toggleStreakHint)

                StatTile(
                    label: Strings.Detail.skipsLeftThisWeek,
                    value: format.skipsOfTotal(left: task.skipsLeft, total: task.skipsPerWeek))
            }
            .fixedSize(horizontal: false, vertical: true)

            Text(Strings.Detail.longest(StreakLabel.string(task.longest, style: .short, mode: settings.mode)))
                .font(Font.app.caption)
                .foregroundStyle(Color.app.textTertiary)
        }
    }

    private var thisWeek: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(Strings.Detail.thisWeek)
            HStack(spacing: 0) {
                ForEach(task.week) { entry in
                    WeekDayCircle(day: entry.day, status: entry.status)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, Spacing.xs)
        }
    }

    private var actions: some View {
        AdaptiveStack {
            PrimaryButton(checkInTitle, systemImage: canCheckIn ? "camera.fill" : nil) {
                showingCheckIn = true
            }
            .disabled(!canCheckIn)

            SecondaryButton(task.skipsLeft == 0 ? Strings.Detail.noSkipsLeft : Strings.Detail.useSkip) {
                // The dialog fades in over this screen rather than sliding up.
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) { showingSkip = true }
            }
            .disabled(!canSkip)
        }
    }

    private var recentCheckIns: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                sectionHeader(Strings.Detail.recentCheckIns)
                Spacer()
                if !task.checkIns.isEmpty {
                    Button { showingHistory = true } label: {
                        Text(Strings.Detail.seeAll)
                            .font(Font.app.meta)
                            .foregroundStyle(Color.app.accentText)
                            .frame(minHeight: Sizes.tapTarget)
                            .contentShape(Rectangle())
                    }
                }
            }
            if task.checkIns.isEmpty {
                Text(Strings.Detail.noCheckIns)
                    .font(Font.app.meta)
                    .foregroundStyle(Color.app.textTertiary)
                    .padding(.top, Spacing.xs)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 4),
                          spacing: Spacing.xs) {
                    ForEach(task.checkIns.prefix(4), id: \.self) { _ in
                        PhotoThumbnail()
                    }
                }
                .padding(.top, Spacing.xs)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Font.app.sectionHeader)
            .foregroundStyle(Color.app.textTertiary)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: Button states

    /// Open window and not done yet. Checking in after a skip is allowed: it gives the skip back.
    private var canCheckIn: Bool {
        switch task.today {
        case .scheduled(.open, .none), .scheduled(.open, .skipped): true
        default: false
        }
    }

    /// "Check in", or why it's disabled: "Opens 6:00 PM", "Closed", "Done today".
    private var checkInTitle: String {
        switch task.today {
        case .scheduled(_, .done): Strings.Detail.doneToday
        case .scheduled(.before, _): Strings.Detail.opens(format.time(task.window.start))
        case .scheduled(.after, _), .notToday: Strings.Detail.closed
        case .scheduled(.open, _): Strings.Detail.checkIn
        }
    }

    private var canSkip: Bool {
        guard task.skipsLeft > 0, case .scheduled(let phase, .none) = task.today else { return false }
        return phase != .after
    }
}

