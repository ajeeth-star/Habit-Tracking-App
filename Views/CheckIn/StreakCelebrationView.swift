import SwiftUI

/// Full-screen celebration right after Submit (design.md §4.8): up to three steps, one after another.
/// 1. The check-in (always): the streak's own count. Closes after 2.5s if it's the only step, or moves on
///    after 2s if more follow; a tap does either sooner.
/// 2. The day streak (only if this check-in completed the day), with a CONTINUE button.
/// 3. A new flame form (only if one was just reached), with a CONTINUE button.
struct StreakCelebrationView: View {
    enum Step: Hashable {
        case checkIn
        case dayStreak
        case newForm(from: FlameForm, to: FlameForm)
    }

    let result: CheckInResult
    /// What this check-in did to the day streak; nil when the day isn't complete yet.
    var dayChange: DayStreakChange?
    /// The flame's form before this check-in (shown in step 1).
    var form: FlameForm
    /// The steps to show. Normally worked out from `dayChange`; the Design Gallery picks its own.
    var steps: [Step]
    /// False keeps step 1 on screen until tapped (the Design Gallery uses this so it can be looked at).
    var closesAutomatically = true
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppSettings.self) private var settings
    @State private var index = 0
    @State private var didClose = false

    init(result: CheckInResult, dayChange: DayStreakChange? = nil, form: FlameForm? = nil, steps: [Step]? = nil,
         closesAutomatically: Bool = true, onDone: @escaping () -> Void) {
        self.result = result
        self.dayChange = dayChange
        self.form = form ?? dayChange?.fromForm ?? .flame
        self.steps = steps ?? Self.steps(for: dayChange)
        self.closesAutomatically = closesAutomatically
        self.onDone = onDone
    }

    /// Step 1 always; step 2 when the day was completed; step 3 when that reached a new form.
    static func steps(for change: DayStreakChange?) -> [Step] {
        guard let change else { return [.checkIn] }
        var steps: [Step] = [.checkIn, .dayStreak]
        if let newForm = change.newForm { steps.append(.newForm(from: change.fromForm, to: newForm)) }
        return steps
    }

    /// No pop, hop, flash, confetti, or count-up with Reduce Motion, or with Settings → Celebration animation off.
    private var animates: Bool { settings.celebrationAnimation && !reduceMotion }
    private var isLastStep: Bool { index >= steps.count - 1 }

    var body: some View {
        ZStack {
            Color.app.background.ignoresSafeArea()
            if index < steps.count {
                stepView(steps[index])
                    .id(index)
                    .transition(animates ? .opacity.combined(with: .scale(scale: 0.96)) : .identity)
            }
        }
        .task(id: index) {
            // Step 1 moves on (or closes) by itself.
            guard closesAutomatically, steps.indices.contains(index), steps[index] == .checkIn else { return }
            try? await Task.sleep(for: isLastStep ? Motion.celebrationDuration : Motion.celebrationAdvance)
            guard !Task.isCancelled else { return }
            advance()
        }
    }

    @ViewBuilder private func stepView(_ step: Step) -> some View {
        switch step {
        case .checkIn:
            CheckInStep(result: result, form: form, animates: animates)
                .contentShape(Rectangle())
                .onTapGesture(perform: advance)
                .accessibilityAction { advance() }
        case .dayStreak:
            DayStreakStep(change: dayChange ?? DayStreakChange(from: 0, to: 1, isRevival: false),
                          animates: animates, onContinue: advance)
        case .newForm(let from, let to):
            NewFormStep(from: from, to: to, animates: animates, onContinue: advance)
        }
    }

    private func advance() {
        if isLastStep {
            guard !didClose else { return }
            didClose = true
            onDone()
        } else {
            withAnimation(animates ? Motion.standard : nil) { index += 1 }
        }
    }
}

/// Step 1: the cheering flame pops in with confetti, and the streak's own count goes up.
private struct CheckInStep: View {
    let result: CheckInResult
    let form: FlameForm
    let animates: Bool

    @Environment(AppSettings.self) private var settings
    @State private var popped = false
    @State private var shownDays: Int?

    private let format = Formatters.current

    /// Always days, whatever the weeks/days toggle says.
    private var streakDays: Int { result.streak.totalCheckIns }

    var body: some View {
        VStack(spacing: 0) {
            FlameCharacterView(form: form, mood: .cheering, size: Sizes.flameCelebration)
                .scaleEffect(popped || !animates ? 1 : Motion.popStartScale)
                .background {
                    // A flat, soft disc in the streak's color (no gradients).
                    Circle()
                        .fill(result.color.badge)
                        .frame(width: Sizes.celebrationGlow, height: Sizes.celebrationGlow)
                        .scaleEffect(popped || !animates ? 1 : Motion.popStartScale)
                        .opacity(popped || !animates ? 1 : 0)
                        .accessibilityHidden(true)
                }
                .background {
                    if animates && popped {
                        ConfettiView().frame(width: 600, height: 900)
                    }
                }
                .padding(.bottom, Spacing.lg)

            Text("\(shownDays ?? (animates ? result.previousStreakDays : streakDays))")
                .font(Font.app.celebrationNumber)
                .foregroundStyle(Color.app.textPrimary)
                .contentTransition(.numericText(value: Double(shownDays ?? result.previousStreakDays)))

            Text(Strings.Celebration.streakName(result.taskName))
                .font(Font.app.dayStreakLabel)
                .capsLabel()
                .foregroundStyle(result.color.main)

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
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
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
            // The flourish, just after the check-in ding.
            try? await Task.sleep(for: .milliseconds(200))
            SoundPlayer.shared.play(.celebration, enabled: settings.sounds)
        }
    }
}
