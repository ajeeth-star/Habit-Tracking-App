import SwiftUI

/// "Your 23-day streak ended" (design.md §4.15): shown once per break, full screen, the first time the app
/// is opened after the day streak ends. Kind, never scolding.
struct DayStreakEndedView: View {
    /// The day streak just before it ended.
    let length: Int
    let longest: Int
    let bestForm: FlameForm
    let onClose: () -> Void

    @Environment(AppSettings.self) private var settings

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: Spacing.xl)
            VStack(spacing: 0) {
                FlameCharacterView(form: .ember, mood: .sad, size: Sizes.flameEnded)
                    .padding(.bottom, Spacing.xl)
                Text(Strings.DayStreakEnded.title(length))
                    .font(Font.app.screenTitle)
                    .foregroundStyle(Color.app.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(Formatters.current.dayStreakStats(longest: longest, bestForm: bestForm))
                    .font(Font.app.subhead)
                    .foregroundStyle(Color.app.textSecondary)
                    .padding(.top, Spacing.xs)
                SpeechBubble(text: Strings.DayStreakEnded.bubble, centered: true)
                    .padding(.top, Spacing.lg)
            }
            .multilineTextAlignment(.center)
            Spacer(minLength: Spacing.xl)
            ChunkyButton(Strings.DayStreakEnded.letsGo, action: onClose)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.app.background)
        .task {
            SoundPlayer.shared.play(.streakEnded, enabled: settings.sounds)
        }
    }
}

extension DayStreakEndedView {
    /// The screen for the latest break in `state`.
    init(state: DayStreakState, onClose: @escaping () -> Void) {
        self.init(length: state.lastBreak?.length ?? 0, longest: state.longest, bestForm: state.bestForm,
                  onClose: onClose)
    }
}
