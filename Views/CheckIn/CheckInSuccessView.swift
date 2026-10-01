import SwiftUI

/// Shown after submitting a check-in (design.md §4.8). Full screen for now; whether it should be a
/// quick popup instead is still open, so it's a self-contained view that's easy to present either way.
struct CheckInSuccessView: View {
    let result: CheckInResult
    let onDone: () -> Void

    @Environment(StreakDisplaySettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private let format = Formatters.current

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "checkmark")
                .font(Font.app.largeIcon)
                .foregroundStyle(Color.app.success)
                .frame(width: Sizes.successCircle, height: Sizes.successCircle)
                .background(Color.app.successSoft, in: Circle())
                .scaleEffect(appeared || reduceMotion ? 1 : 0.6)
                .accessibilityHidden(true)

            Text(Strings.Success.done(result.taskName))
                .font(Font.app.successTitle)
                .foregroundStyle(Color.app.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.md)

            Text(Strings.Success.streak(format.streakFull(result.streak, mode: settings.mode)))
                .font(Font.app.subhead)
                .monospacedDigit()
                .foregroundStyle(Color.app.textSecondary)
                .padding(.top, Spacing.xs)

            VStack(spacing: Spacing.xxs) {
                Text(format.weekProgress(remaining: result.remainingThisWeek))
                if let skipsLeft = result.refundedSkipsLeft {
                    Text(Strings.Success.skipBack(skipsLeft))
                }
            }
            .font(Font.app.meta)
            .foregroundStyle(Color.app.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.top, Spacing.xxs)

            Spacer()

            SecondaryButton(Strings.Success.backToToday, action: onDone)
                .padding(.bottom, Spacing.lg)
        }
        .padding(.horizontal, Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color.app.background)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.35)) {
                appeared = true
            }
        }
        .sensoryFeedback(.success, trigger: appeared)
    }
}
