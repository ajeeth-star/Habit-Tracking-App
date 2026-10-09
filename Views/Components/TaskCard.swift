import SwiftUI

/// A task on the home screen (design.md §4.1). The open task is the hero card: a chunky card in its
/// streak's color with a live "Closes in" countdown and the Check in button. Every other state is a
/// tappable chunky card that presses down.
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
        if state == .open {
            hero
                .padding(Spacing.md)
                .chunkyCard(fill: task.color.main, lip: task.color.lip, outline: nil)
        } else {
            Button(action: onOpen) {
                compact(state)
                    .padding(Spacing.md)
            }
            .buttonStyle(ChunkyCardButtonStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText(state))
            .accessibilityAddTraits(.isButton)
        }
    }

    // MARK: Hero (open)

    private var hero: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                IconBadge(task: task, onHero: true)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .firstTextBaseline) {
                        Text(task.name)
                            .font(Font.app.cardTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        StreakLabel.text(task.streak, style: .short, mode: settings.streakDisplay,
                                         flameColor: Color.app.textOnBright, dimsZero: false)
                            .font(Font.app.statValue)
                            .contentTransition(.numericText())
                    }
                    .foregroundStyle(Color.app.textOnBright)

                    Text(heroMeta)
                        .font(Font.app.meta)
                        .monospacedDigit()
                        .foregroundStyle(Color.app.onBrightMuted)
                        .contentTransition(.numericText())
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText(.open))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onOpen() }

            ChunkyButton(Strings.Home.checkIn, systemImage: "camera.fill", style: .white(label: task.color.main),
                         action: onCheckIn)
        }
    }

    /// "Closes in 1h 20m · 1 skip left"
    private var heroMeta: String {
        format.closesIn(minutes: task.minutesUntilClose(from: now)) + Strings.separator + format.skipsLeft(task.skipsLeft)
    }

    // MARK: Compact (every other state)

    private func compact(_ state: TaskCardState) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            IconBadge(task: task)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .firstTextBaseline) {
                    Text(task.name)
                        .font(Font.app.cardTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    StreakLabel.text(task.streak, style: .short, mode: settings.streakDisplay)
                        .font(Font.app.cardStreak)
                        .contentTransition(.numericText())
                }
                .foregroundStyle(nameColor(state))

                if let line = statusLine(state) {
                    line
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let ended = task.streakEnded {
                    Text(format.streakEndedLine(ended, today: Weekday(now)))
                        .font(Font.app.meta)
                        .foregroundStyle(Color.app.danger)
                    Text(format.longestLine(for: task, today: Weekday(now)))
                        .font(Font.app.meta)
                        .foregroundStyle(Color.app.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// The status in caps, then " · " and the meta line, wrapping as one line: "OPENS 9:00 PM · 1 skip left".
    private func statusLine(_ state: TaskCardState) -> Text? {
        let pill = pill(state).map { StatusPill(kind: $0).styledText }
        let meta = metaText(state).map {
            Text($0).font(Font.app.meta).foregroundStyle(Color.app.textSecondary)
        }
        switch (pill, meta) {
        case let (pill?, meta?):
            return pill + Text(Strings.separator).font(Font.app.meta).foregroundStyle(Color.app.textTertiary) + meta
        case let (pill?, nil): return pill
        case let (nil, meta?): return meta
        case (nil, nil): return nil
        }
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
        case .done(let time): .done(format.time(time))
        case .upcoming: .upcoming(format.time(task.window.start))
        case .skipped: .skipped
        case .missed: .missed
        case .notToday: nil
        }
    }

    private func metaText(_ state: TaskCardState) -> String? {
        switch state {
        case .open: heroMeta
        case .done: task.nextDay(after: Weekday(now)).map { Strings.Home.nextDay(format.nextDay($0)) }
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
            sentences.append(format.streakEndedLine(ended, today: Weekday(now)))
            sentences.append(format.longestLine(for: task, today: Weekday(now)))
        }
        return sentences.joined(separator: ". ") + "."
    }
}

