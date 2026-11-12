import SwiftUI

/// A streak on the Streaks tab's grid (design.md §4.10): a bright tile in the streak's color with its icon,
/// today's status, the streak in big numbers, this week's days as dots, and its best streak. A streak at 0 is
/// drawn faded, so it looks dormant rather than broken. Wrap it in a Button with `StreakTileButtonStyle`.
struct StreakTile: View {
    let task: TaskSnapshot
    @Environment(AppSettings.self) private var settings

    private let format = Formatters.current

    private var isDormant: Bool { task.streak.totalCheckIns == 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: task.icon)
                    .font(Font.app.badgeIcon)
                    .frame(width: Sizes.tileBadge, height: Sizes.tileBadge)
                    .background(Color.app.heroBadge, in: .rounded(Radius.md))
                Spacer(minLength: Spacing.xs)
                status
            }
            Spacer(minLength: Spacing.xs)
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                Image(systemName: "flame.fill")
                    .font(Font.app.cardTitle)
                    .foregroundStyle(isDormant ? Color.app.onBrightMuted : Color.app.textOnBright)
                Text(StreakLabel.string(task.streak, style: .short, mode: settings.streakDisplay))
                    .font(Font.app.streakTileNumber)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())
            }
            Text(task.name)
                .font(Font.app.cardTitle)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.xs)
            weekDots
            Text(Strings.Habits.tileBest(format.streakCompact(task.best, mode: settings.streakDisplay)))
                .font(Font.app.caption)
                .lineLimit(1)
                .padding(.top, Spacing.xxs)
        }
        .foregroundStyle(Color.app.textOnBright)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .aspectRatio(1 / Sizes.tileAspect, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("tile." + task.name)
    }

    /// Done: a checkmark. Open, skipped, missed: a word. Not scheduled today, or not open yet: nothing.
    @ViewBuilder private var status: some View {
        switch task.cardState {
        case .done:
            Image(systemName: "checkmark")
                .font(Font.app.badgeIcon)
                .fontWeight(.heavy)
        case .open: statusWord(Strings.Habits.open)
        case .skipped: statusWord(Strings.Habits.skipped)
        case .missed: statusWord(Strings.Habits.missed)
        case .upcoming, .notToday: EmptyView()
        }
    }

    private func statusWord(_ text: String) -> some View {
        Text(text)
            .font(Font.app.pill)
            .capsLabel()
            .lineLimit(1)
    }

    /// This week's scheduled days: done filled, upcoming or today a ring, skipped faded, missed a small x.
    private var weekDots: some View {
        HStack(spacing: Spacing.xxs) {
            ForEach(task.week) { entry in
                Group {
                    switch entry.status {
                    case .done:
                        Circle().fill(Color.app.textOnBright)
                    case .skipped:
                        Circle().fill(Color.app.textOnBright).opacity(Sizes.tileSkippedDotOpacity)
                    case .today, .upcoming:
                        Circle().strokeBorder(Color.app.textOnBright, lineWidth: Sizes.tileDotRing)
                    case .missed:
                        Image(systemName: "xmark")
                            .font(Font.app.tileDotIcon)
                    }
                }
                .frame(width: Sizes.tileDot, height: Sizes.tileDot)
            }
        }
        .accessibilityHidden(true)
    }

    /// "Gym, 3w 2d, Open now, Best 5w 1d": name first.
    private var accessibilityText: String {
        var parts = [task.name, StreakLabel.string(task.streak, style: .short, mode: settings.streakDisplay)]
        switch task.cardState {
        case .done: parts.append(Strings.Habits.done)
        case .open: parts.append(Strings.Habits.openNow)
        case .skipped: parts.append(Strings.Habits.skipped)
        case .missed: parts.append(Strings.Habits.missed)
        case .upcoming, .notToday: break
        }
        parts.append(Strings.Habits.tileBest(format.streakCompact(task.best, mode: settings.streakDisplay)))
        return parts.joined(separator: ", ")
    }
}

/// The tile's look: the streak's color with its lip as a 5pt bottom edge, rounded 20, pressing down 3pt.
/// A dormant (0) streak is drawn at 45% saturation.
struct StreakTileButtonStyle: ButtonStyle {
    let color: StreakColor
    var dormant = false

    func makeBody(configuration: Configuration) -> some View {
        Styled(configuration: configuration, color: color, dormant: dormant)
    }

    private struct Styled: View {
        let configuration: Configuration
        let color: StreakColor
        let dormant: Bool
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        private var pressed: Bool { configuration.isPressed && !reduceMotion }

        var body: some View {
            configuration.label
                .background(color.main, in: .rounded(Radius.xl))
                .contentShape(.rounded(Radius.xl))
                .offset(y: pressed ? Sizes.cardPress : 0)
                .background(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                        .fill(color.lip)
                        .offset(y: Sizes.cardLip)
                }
                .padding(.bottom, Sizes.cardLip)
                .saturation(dormant ? Sizes.tileDormantSaturation : 1)
                .animation(reduceMotion ? nil : Motion.press, value: configuration.isPressed)
        }
    }
}

/// The grid's last tile (design.md §2): a dashed outline with a + and "New streak". Opens the create form.
struct NewStreakTile: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: "plus")
                    .font(Font.app.circleButtonIcon)
                Text(Strings.Habits.newStreak)
                    .font(Font.app.cardTitle)
            }
            .foregroundStyle(Color.app.textTertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                    .strokeBorder(Color.app.textTertiary,
                                  style: StrokeStyle(lineWidth: Sizes.borderWidth, dash: [Spacing.xs, Spacing.xxs]))
            }
            .contentShape(.rounded(Radius.xl))
            .aspectRatio(1 / Sizes.tileAspect, contentMode: .fit)
            .padding(.bottom, Sizes.cardLip)
        }
        .buttonStyle(PressDownStyle())
        .accessibilityLabel(Strings.Habits.newStreak)
        .accessibilityIdentifier("tile.new")
    }
}

/// Moves down 3pt while pressed, like a tappable card.
private struct PressDownStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Styled(configuration: configuration)
    }

    private struct Styled: View {
        let configuration: Configuration
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            configuration.label
                .offset(y: configuration.isPressed && !reduceMotion ? Sizes.cardPress : 0)
                .animation(reduceMotion ? nil : Motion.press, value: configuration.isPressed)
        }
    }
}

/// Tiles pop in (85% → 100% with a springy fade) the first time a screen appears, 50ms apart (design.md §1.6).
/// Not repeated when you come back. Off with Reduce Motion.
struct PopIn: ViewModifier {
    let index: Int
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown || reduceMotion ? 1 : 0)
            .scaleEffect(shown || reduceMotion ? 1 : Motion.tilePopStartScale)
            .onAppear {
                guard !shown else { return }
                if reduceMotion {
                    shown = true
                } else {
                    let delay = Double(min(index, Motion.slideInMaxStaggered)) * Motion.tilePopStagger
                    withAnimation(Motion.tilePop.delay(delay)) { shown = true }
                }
            }
    }
}

extension View {
    /// Pop in on first appearance; `index` sets the stagger.
    func appearPop(index: Int) -> some View {
        modifier(PopIn(index: index))
    }
}
