import SwiftUI

/// A streak on the Streaks tab (design.md §4.10): name, schedule, today's status on the left; current
/// streak and best streak on the right. Wrap it in a Button with `ChunkyCardButtonStyle` for the card. Archived rows show only the name and best streak.
struct HabitRow: View {
    let task: TaskSnapshot
    @Environment(AppSettings.self) private var settings

    private let format = Formatters.current

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            IconBadge(task: task)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(task.name)
                    .font(Font.app.cardTitle)
                    .foregroundStyle(task.isArchived ? Color.app.textTertiary : Color.app.textPrimary)
                if !task.isArchived {
                    Text(format.schedule(days: task.days, window: task.window))
                        .font(Font.app.meta)
                        .foregroundStyle(Color.app.textSecondary)
                    status
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                if !task.isArchived {
                    StreakLabel.text(task.streak, style: .short, mode: settings.streakDisplay)
                        .font(Font.app.cardStreak)
                        .contentTransition(.numericText())
                        .foregroundStyle(Color.app.textPrimary)
                }
                Text(format.best(task.best, mode: settings.streakDisplay))
                    .font(Font.app.caption)
                    .foregroundStyle(Color.app.textTertiary)
            }
            if task.isArchived {
                Image(systemName: "chevron.right")
                    .font(Font.app.meta)
                    .foregroundStyle(Color.app.textTertiary)
            }
        }
        .padding(Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder private var status: some View {
        switch task.cardState {
        case .open: StatusPill(kind: .open)
        case .done(let time): StatusPill(kind: .done(format.time(time)))
        case .upcoming: StatusPill(kind: .upcoming(format.time(task.window.start)))
        case .skipped: StatusPill(kind: .skipped)
        case .missed: StatusPill(kind: .missed)
        case .notToday:
            Text(Strings.Habits.notToday)
                .font(Font.app.meta)
                .foregroundStyle(Color.app.textTertiary)
        }
    }
}
