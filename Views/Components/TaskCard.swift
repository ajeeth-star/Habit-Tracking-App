import SwiftUI

/// A task on the home screen (design.md §4.1). The open task is the hero card: accent fill, a live
/// "Closes in" countdown, and the Check in button. Every other state is a compact surface card.
struct TaskCard: View {
    let task: TaskSnapshot
    /// The current time, for the countdown and "Next: Friday".
    let now: Date
    let onOpen: () -> Void
    let onCheckIn: () -> Void
    @Environment(AppSettings.self) private var settings

    private let format = Formatters.current

    var body: some View {
        let state = task.cardState
        Group {
            if state == .open {
                hero
            } else {
                compact(state)
            }
        }
        .padding(Spacing.md)
        .background(state == .open ? Color.app.accent : Color.app.surface, in: .rounded(Radius.lg))
        .overlay {
            if state != .open {
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .strokeBorder(Color.app.separator, lineWidth: Sizes.hairline)
            }
        }
    }

    // MARK: Hero (open)

    private var hero: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .firstTextBaseline) {
                    Text(task.name)
                        .font(Font.app.cardTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    StreakLabel.text(task.streak, style: .short, mode: settings.streakDisplay, flameColor: Color.app.onAccent)
                        .font(Font.app.statValue)
                }
                .foregroundStyle(Color.app.onAccent)

                Text(heroMeta)
                    .font(Font.app.meta)
                    .monospacedDigit()
                    .foregroundStyle(Color.app.onAccentMuted)
            }
            .modifier(OpensTask(label: accessibilityText(.open), action: onOpen))

            PrimaryButton(Strings.Home.checkIn, systemImage: "camera.fill", inverted: true, action: onCheckIn)
        }
    }

    /// "Closes in 1h 20m · 1 skip left"
    private var heroMeta: String {
        format.closesIn(minutes: task.minutesUntilClose(from: now)) + Strings.separator + format.skipsLeft(task.skipsLeft)
    }

    // MARK: Compact (every other state)

    private func compact(_ state: TaskCardState) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .firstTextBaseline) {
                Text(task.name)
                    .font(Font.app.cardTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                StreakLabel.text(task.streak, style: .short, mode: settings.streakDisplay)
                    .font(Font.app.cardStreak)
            }
            .foregroundStyle(nameColor(state))

            let meta = metaText(state)
            if pill(state) != nil || meta != nil {
                AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .center) {
                    if let pill = pill(state) {
                        StatusPill(kind: pill)
                    }
                    if let meta {
                        Text(meta)
                            .font(Font.app.meta)
                            .monospacedDigit()
                            .foregroundStyle(Color.app.textSecondary)
                    }
                }
            }

            if let ended = task.streakEnded {
                Text(Strings.Home.streakEnded(format.weekdayName(ended.on), format.streakShort(ended.at)))
                    .font(Font.app.meta)
                    .foregroundStyle(Color.app.danger)
                Text(Strings.Home.longestStartsFresh(format.streakShort(task.longest)))
                    .font(Font.app.meta)
                    .foregroundStyle(Color.app.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(OpensTask(label: accessibilityText(state), action: onOpen))
    }

    private func nameColor(_ state: TaskCardState) -> Color {
        switch state {
        case .done: Color.app.textSecondary
        case .notToday: Color.app.textTertiary
        default: Color.app.textPrimary
        }
    }

    private func pill(_ state: TaskCardState) -> StatusPill.Kind? {
        switch state {
        case .open: .open
        case .done: .done
        case .upcoming: .upcoming(format.time(task.window.start))
        case .skipped: .skipped
        case .missed: .missed
        case .notToday: nil
        }
    }

    private func metaText(_ state: TaskCardState) -> String? {
        switch state {
        case .open: heroMeta
        case .done(let time): format.doneMeta(checkedInAt: time, next: task.nextDay(after: Weekday(now)))
        case .upcoming, .skipped: format.skipsLeft(task.skipsLeft)
        case .missed: nil
        case .notToday(let next): Strings.Home.next(format.nextDay(next), format.window(task.window))
        }
    }

    /// Reads as one sentence, e.g. "Gym. Open now. Closes in 1h 30m · 1 skip left. Streak 3w 2d."
    private func accessibilityText(_ state: TaskCardState) -> String {
        var sentences = [task.name]
        if let pill = pill(state) { sentences.append(StatusPill(kind: pill).text) }
        if let meta = metaText(state) { sentences.append(meta) }
        sentences.append(Strings.Accessibility.streak(StreakLabel.string(task.streak, style: .short, mode: settings.streakDisplay)))
        if let ended = task.streakEnded {
            sentences.append(Strings.Home.streakEnded(format.weekdayName(ended.on), format.streakShort(ended.at)))
            sentences.append(Strings.Home.longestStartsFresh(format.streakShort(task.longest)))
        }
        return sentences.joined(separator: ". ") + "."
    }
}

/// Tapping a card's text opens the task; VoiceOver reads it as one button. The Check in button stays separate.
private struct OpensTask: ViewModifier {
    let label: String
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { action() }
    }
}
