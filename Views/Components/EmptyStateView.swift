import SwiftUI

/// What Home shows before any streak exists (design.md §4.2): the happy Ember says hi, with a button
/// to create the first streak.
struct EmptyStateView: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            FlameCharacterView(form: .ember, mood: .happy, size: Sizes.flameEmpty)
            SpeechBubble(text: Strings.Bubble.empty, centered: true)
                .padding(.top, Spacing.sm)
            ChunkyButton(Strings.Home.createAStreak, systemImage: "plus", action: onCreate)
                .padding(.top, Spacing.xl)
        }
        .frame(maxWidth: .infinity)
    }
}
