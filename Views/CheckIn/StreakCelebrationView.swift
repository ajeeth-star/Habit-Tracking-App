import SwiftUI

/// Full-screen celebration right after Submit (design.md §4.8): the flame pops in, the streak counts up
/// in days, then it closes on its own after 2.5 seconds. Tapping anywhere closes it sooner.
struct StreakCelebrationView: View {
    let result: CheckInResult
    /// False keeps it on screen (the Design Gallery uses this so it can be looked at).
    var closesAutomatically = true
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppSettings.self) private var settings
    @State private var popped = false
    @State private var shownDays: Int?
    @State private var didClose = false

    private let format = Formatters.current

    /// No pop or count-up with Reduce Motion, or with Settings → Celebration animation off.
    private var animates: Bool { settings.celebrationAnimation && !reduceMotion }

    /// Always days, whatever the weeks/days toggle says.
    private var streakDays: Int { result.streak.totalCheckIns }

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "flame.fill")
                .font(Font.app.celebrationIcon)
                .foregroundStyle(Color.app.streak)
                .scaleEffect(popped || !animates ? 1 : Motion.popStartScale)
                .background {
                    // A soft glow in the streak's color, one of the three places gradients are allowed.
                    Circle()
                        .fill(RadialGradient(colors: [result.color.main.opacity(Motion.glowOpacity), .clear],
                                             center: .center, startRadius: 0,
                                             endRadius: Sizes.celebrationGlow / 2))
                        .frame(width: Sizes.celebrationGlow, height: Sizes.celebrationGlow)
                        .scaleEffect(popped || !animates ? 1 : Motion.popStartScale)
                        .opacity(popped || !animates ? 1 : 0)
                        .accessibilityHidden(true)
                }

            Text("\(shownDays ?? (animates ? result.previousStreakDays : streakDays))")
                .font(Font.app.celebrationNumber)
                .foregroundStyle(Color.app.textPrimary)
                .contentTransition(.numericText(value: Double(shownDays ?? result.previousStreakDays)))

            Text(Strings.Celebration.dayStreak)
                .font(Font.app.subhead)
                .foregroundStyle(Color.app.textSecondary)

            Text(Strings.Celebration.done(result.taskName))
                .font(Font.app.successTitle)
                .foregroundStyle(Color.app.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.lg)

            VStack(spacing: Spacing.xxs) {
                Text(format.weekProgress(remaining: result.remainingThisWeek))
                if let skipsLeft = result.refundedSkipsLeft {
                    Text(Strings.Celebration.skipBack(skipsLeft))
                }
            }
            .font(Font.app.meta)
            .foregroundStyle(Color.app.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.top, Spacing.xxs)
        }
        .padding(.horizontal, Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.app.background)
        .contentShape(Rectangle())
        .onTapGesture(perform: close)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { close() }
        .sensoryFeedback(trigger: popped) { _, didPop in
            settings.vibrations && didPop ? .success : nil
        }
        .task {
            if !animates {
                shownDays = streakDays
                popped = true
            } else {
                withAnimation(Motion.pop) { popped = true }
                try? await Task.sleep(for: .milliseconds(250))
                withAnimation(Motion.settle) { shownDays = streakDays }
            }
        }
        .task {
            guard closesAutomatically else { return }
            try? await Task.sleep(for: Motion.celebrationDuration)
            close()
        }
    }

    private func close() {
        guard !didClose else { return }
        didClose = true
        onDone()
    }
}
