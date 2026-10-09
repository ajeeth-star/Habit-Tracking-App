import SwiftUI

/// The flame icon followed by the formatted streak. Follows the owner's weeks/days-only toggle.
struct StreakLabel: View {
    enum Style {
        /// "3w 2d"
        case short
        /// "3 weeks 2 days"
        case long
    }

    let streak: Streak
    var style: Style = .short
    @Environment(AppSettings.self) private var settings

    var body: some View {
        StreakLabel.text(streak, style: style, mode: settings.streakDisplay)
    }

    static func string(_ streak: Streak, style: Style, mode: StreakDisplayMode) -> String {
        switch style {
        case .short: Formatters.current.streakCompact(streak, mode: mode)
        case .long: Formatters.current.streakFull(streak, mode: mode)
        }
    }

    /// The same label as `Text`, so it can sit inline inside a longer line.
    /// `flameColor` is `flame` everywhere except on a bright fill (the hero card), where it's `textOnBright`.
    /// A zero streak shows a grey flame and "0" (unless `dimsZero` is off, e.g. on a bright hero card).
    static func text(_ streak: Streak, style: Style, mode: StreakDisplayMode,
                     flameColor: Color = Color.app.flame, dimsZero: Bool = true) -> Text {
        let isZero = streak.weeks == 0 && streak.days == 0 && streak.totalCheckIns == 0
        return Text(Image(systemName: "flame.fill")).foregroundStyle(isZero && dimsZero ? Color.app.textTertiary : flameColor)
            + Text(" " + string(streak, style: style, mode: mode)).monospacedDigit()
    }
}
