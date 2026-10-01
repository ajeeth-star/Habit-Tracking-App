import SwiftUI

/// A task on the home screen. Its look depends on the task's state today (design.md §4.1).
struct TaskCard: View {
    let task: TaskSnapshot
    let onOpen: () -> Void
    let onCheckIn: () -> Void
    @Environment(StreakDisplaySettings.self) private var settings

    private let format = Formatters.current

    var body: some View {
        let state = task.cardState
        VStack(alignment: .leading, spacing: Spacing.sm) {
            summary(state)
                .contentShape(Rectangle())
                .onTapGesture(perform: onOpen)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityText(state))
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { onOpen() }

            if state == .open {
                PrimaryButton(Strings.Home.checkIn, systemImage: "camera.fill", action: onCheckIn)
            }
        }
        .padding(Spacing.md)
        .background(Color.app.surface, in: .rounded(Radius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .strokeBorder(
                    state == .open ? Color.app.accent : Color.app.separator,
                    lineWidth: state == .open ? Sizes.emphasisStroke : Sizes.hairline
                )
        }
    }

    // MARK: Pieces

    private func summary(_ state: TaskCardState) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .firstTextBaseline) {
                Text(task.name)
                    .font(Font.app.cardTitle)
                    .foregroundStyle(isNotToday(state) ? Color.app.textTertiary : Color.app.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let pill = pill(state) {
                    StatusPill(kind: pill)
                }
            }

            if let meta = metaLine(state) {
                meta
                    .font(Font.app.meta)
                    .foregroundStyle(Color.app.textSecondary)
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

    /// The meta line's parts, in order. `streak` marks where the flame label goes.
    private enum MetaPart {
        case text(String)
        case streak
    }

    private func metaParts(_ state: TaskCardState) -> [MetaPart] {
        switch state {
        case .open:
            [.text(Strings.Home.closes(format.time(task.window.end))), .streak, .text(format.skipsLeft(task.skipsLeft))]
        case .done(let time):
            [.text(Strings.Home.checkedIn(format.time(time))), .streak]
        case .upcoming:
            [.streak, .text(format.skipsLeft(task.skipsLeft))]
        case .skipped:
            [.streak, .text(format.skipsLeft(task.skipsLeft))]
        case .missed:
            []
        case .notToday(let next):
            [.text(Strings.Home.next(format.nextDay(next), format.window(task.window))), .streak]
        }
    }

    private func metaLine(_ state: TaskCardState) -> Text? {
        let parts = metaParts(state)
        guard !parts.isEmpty else { return nil }
        var line = Text("")
        for (index, part) in parts.enumerated() {
            if index > 0 { line = line + Text(Strings.separator) }
            switch part {
            case .text(let string): line = line + Text(string).monospacedDigit()
            case .streak: line = line + StreakLabel.text(task.streak, style: .short, mode: settings.mode)
            }
        }
        return line
    }

    /// Reads as one sentence, e.g. "Gym. Open now. Closes 8:00 PM. Streak 12 days. 1 skip left."
    private func accessibilityText(_ state: TaskCardState) -> String {
        var sentences = [task.name]
        if let pill = pill(state) { sentences.append(StatusPill(kind: pill).text) }
        for part in metaParts(state) {
            switch part {
            case .text(let string): sentences.append(string)
            case .streak:
                sentences.append(Strings.Accessibility.streak(
                    StreakLabel.string(task.streak, style: .short, mode: settings.mode)))
            }
        }
        if let ended = task.streakEnded {
            sentences.append(Strings.Home.streakEnded(format.weekdayName(ended.on), format.streakShort(ended.at)))
            sentences.append(Strings.Home.longestStartsFresh(format.streakShort(task.longest)))
        }
        return sentences.joined(separator: ". ") + "."
    }

    private func isNotToday(_ state: TaskCardState) -> Bool {
        if case .notToday = state { true } else { false }
    }
}
