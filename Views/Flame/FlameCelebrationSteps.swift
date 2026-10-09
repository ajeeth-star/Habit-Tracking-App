import SwiftUI

/// Celebration step 2 (design.md §4.8): the day streak counts up, the flame hops, and the milestone bar
/// shows how far it is to the next form.
struct DayStreakStep: View {
    let change: DayStreakChange
    let animates: Bool
    let onContinue: () -> Void

    @Environment(AppSettings.self) private var settings
    @State private var landed = false
    @State private var hops = 0

    private var shownDays: Int { landed || !animates ? change.to : change.from }
    private var shownForm: FlameForm { FlameForm(days: shownDays) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: Spacing.xl)
            VStack(spacing: 0) {
                if change.isRevival {
                    Text(Strings.Celebration.flameBack)
                        .font(Font.app.screenTitle)
                        .foregroundStyle(Color.app.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, Spacing.lg)
                }

                FlameCharacterView(form: shownForm, mood: .cheering, size: Sizes.flameCelebration)
                    .keyframeAnimator(initialValue: 0.0, trigger: hops) { flame, y in
                        flame.offset(y: y)
                    } keyframes: { _ in
                        KeyframeTrack {
                            SpringKeyframe(-Motion.hopHeight, duration: 0.18)
                            SpringKeyframe(0, duration: 0.35)
                        }
                    }
                    .padding(.bottom, Spacing.lg)

                Text(Strings.Flame.dayStreak)
                    .font(Font.app.dayStreakLabel)
                    .capsLabel()
                    .foregroundStyle(Color.app.textSecondary)
                Text("\(shownDays)")
                    .font(Font.app.celebrationNumber)
                    .foregroundStyle(Color.app.flame)
                    .contentTransition(.numericText(value: Double(shownDays)))

                MilestoneBar(days: change.to)
                    .padding(.top, Spacing.lg)

                Text(Formatters.current.toNextForm(days: change.to))
                    .font(Font.app.subhead)
                    .foregroundStyle(Color.app.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.md)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: Spacing.xl)
            ChunkyButton(Strings.Celebration.continue, action: onContinue)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.lg)
        .sensoryFeedback(trigger: landed) { _, didLand in
            settings.vibrations && didLand ? .success : nil
        }
        .task {
            guard animates else { return }
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(Motion.pop) { landed = true }
            hops += 1
        }
    }
}

/// Last milestone reached (checked), today's spot (glowing), and the next milestone (dim).
private struct MilestoneBar: View {
    let days: Int

    private var current: FlameForm { FlameForm(days: days) }
    /// The milestone behind today: the current form's start, or the one before when today is that start.
    private var previous: FlameForm {
        days == current.minimumDays && current != .ember ? FlameForm(rawValue: current.rawValue - 1) ?? .ember : current
    }
    private var next: FlameForm? { current.next }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: 0) {
                Image(systemName: "checkmark")
                    .font(Font.app.badgeIcon)
                    .fontWeight(.heavy)
                    .foregroundStyle(Color.app.textOnBright)
                    .frame(width: Sizes.milestoneNode, height: Sizes.milestoneNode)
                    .background(Color.app.flame, in: Circle())
                Capsule().fill(Color.app.flame).frame(height: Sizes.milestoneTrack)
                Text("\(days)")
                    .font(Font.app.statValue)
                    .foregroundStyle(Color.app.textOnBright)
                    .minimumScaleFactor(0.6)
                    .frame(width: Sizes.milestoneCurrent, height: Sizes.milestoneCurrent)
                    .background(Color.app.flame, in: Circle())
                    .background {
                        Circle()
                            .fill(Color.app.flameSoft)
                            .padding(-Sizes.milestoneGlow)
                    }
                if let next {
                    Capsule().fill(Color.app.track).frame(height: Sizes.milestoneTrack)
                    Text("\(next.minimumDays)")
                        .font(Font.app.meta)
                        .monospacedDigit()
                        .foregroundStyle(Color.app.textTertiary)
                        .minimumScaleFactor(0.6)
                        .frame(width: Sizes.milestoneNode, height: Sizes.milestoneNode)
                        .background(Color.app.surfaceMuted, in: Circle())
                }
            }
            HStack {
                Text(Strings.Flame.formName(previous))
                    .foregroundStyle(Color.app.textSecondary)
                Spacer()
                if let next {
                    Text(Strings.Flame.formName(next))
                        .foregroundStyle(Color.app.textTertiary)
                }
            }
            .font(Font.app.caption)
        }
        .padding(.horizontal, Spacing.xs)
        .accessibilityHidden(true)
    }
}

/// Celebration step 3 (design.md §4.8): the old form shrinks, a white flash, and the new form bursts in.
struct NewFormStep: View {
    let from: FlameForm
    let to: FlameForm
    let animates: Bool
    let onContinue: () -> Void

    @Environment(AppSettings.self) private var settings

    private enum Phase { case old, shrunk, burst }
    @State private var phase = Phase.old
    @State private var flashing = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: Spacing.xl)
            VStack(spacing: 0) {
                FlameCharacterView(form: phase == .burst ? to : from, mood: .cheering, size: Sizes.flameCelebration)
                    .scaleEffect(phase == .shrunk ? 0.3 : 1)
                    .background {
                        if animates && phase == .burst {
                            ZStack {
                                ConfettiView()
                                ConfettiView()
                            }
                            .frame(width: 600, height: 900)
                        }
                    }
                    .padding(.bottom, Spacing.xl)

                Group {
                    Text(Strings.Celebration.becameForm(Strings.Flame.formName(to)))
                        .font(Font.app.screenTitle)
                        .foregroundStyle(Color.app.textPrimary)
                    Text(Strings.Flame.formDescription(to))
                        .font(Font.app.subhead)
                        .foregroundStyle(Color.app.textSecondary)
                        .padding(.top, Spacing.xs)
                }
                .multilineTextAlignment(.center)
                .opacity(phase == .burst ? 1 : 0)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: Spacing.xl)
            ChunkyButton(Strings.Celebration.continue, action: onContinue)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.lg)
        .overlay {
            Color.app.flash
                .ignoresSafeArea()
                .opacity(flashing ? 1 : 0)
                .allowsHitTesting(false)
        }
        .sensoryFeedback(trigger: phase) { _, phase in
            settings.vibrations && phase == .burst ? .success : nil
        }
        .task {
            guard animates else {
                phase = .burst
                SoundPlayer.shared.play(.evolution, enabled: settings.sounds)
                return
            }
            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.easeIn(duration: 0.35)) { phase = .shrunk }
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(.easeIn(duration: 0.05)) { flashing = true }
            try? await Task.sleep(for: .seconds(Motion.evolutionFlash))
            SoundPlayer.shared.play(.evolution, enabled: settings.sounds)
            withAnimation(.easeOut(duration: 0.15)) { flashing = false }
            withAnimation(Motion.pop) { phase = .burst }
        }
    }
}
