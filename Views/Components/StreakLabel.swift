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
    @Environment(StreakDisplaySettings.self) private var settings

    var body: some View {
        StreakLabel.text(streak, style: style, mode: settings.mode)
    }

    static func string(_ streak: Streak, style: Style, mode: StreakDisplayMode) -> String {
        switch style {
        case .short: Formatters.current.streakCompact(streak, mode: mode)
        case .long: Formatters.current.streakFull(streak, mode: mode)
        }
    }

    /// The same label as `Text`, so it can sit inline inside a longer line (like a card's meta line).
    static func text(_ streak: Streak, style: Style, mode: StreakDisplayMode) -> Text {
        Text(Image(systemName: "flame.fill")).foregroundStyle(Color.app.streak)
            + Text(" " + string(streak, style: style, mode: mode)).monospacedDigit()
    }
}
