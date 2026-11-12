import SwiftUI

/// What Today and the Streaks tab show before any streak exists (design.md §4.2): the happy Ember says hi,
/// "Popular streaks" chips open the create form filled in, and a button creates a custom streak.
struct EmptyStateView: View {
    var onPick: (StreakPreset) -> Void = { _ in }
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            FlameCharacterView(form: .ember, mood: .happy, size: Sizes.flameEmpty)
            SpeechBubble(text: Strings.Bubble.empty, centered: true)
                .padding(.top, Spacing.sm)
            Text(Strings.Starters.title)
                .font(Font.app.sectionHeader)
                .foregroundStyle(Color.app.textTertiary)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, Spacing.xl)
            FlowLayout {
                ForEach(StreakPreset.popular) { preset in
                    StarterChip(preset: preset) { onPick(preset) }
                }
            }
            .padding(.top, Spacing.xs)
            ChunkyButton(Strings.Home.createAStreak, systemImage: "plus", action: onCreate)
                .padding(.top, Spacing.xl)
        }
        .frame(maxWidth: .infinity)
    }
}
