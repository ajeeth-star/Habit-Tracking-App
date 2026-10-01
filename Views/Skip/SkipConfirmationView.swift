import SwiftUI

/// The "Use your last skip?" dialog (design.md §4.5). A custom dialog rather than Apple's alert,
/// so "Keep my skip" can be the highlighted button. Present it full screen with a clear background.
struct SkipConfirmationView: View {
    let prompt: SkipPrompt
    /// Called after "Use skip". Nothing is saved in this phase.
    var onUseSkip: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var scrimVisible = false
    @State private var usedSkip = false

    private let format = Formatters.current

    var body: some View {
        ZStack {
            Color.app.scrim
                .ignoresSafeArea()
                .opacity(scrimVisible ? 1 : 0)
                // Tapping outside counts as "Keep my skip".
                .onTapGesture(perform: close)
                .accessibilityHidden(true)

            card
                .opacity(scrimVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { scrimVisible = true }
        }
        .sensoryFeedback(.warning, trigger: usedSkip)
    }

    private var card: some View {
        GeometryReader { proxy in
            // At very large text sizes the dialog can be taller than the screen; then it scrolls.
            ViewThatFits(in: .vertical) {
                cardContent(width: proxy.size.width)
                ScrollView {
                    cardContent(width: proxy.size.width)
                        .padding(.vertical, Spacing.lg)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func cardContent(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            Text(format.skipTitle(prompt))
                .font(Font.app.cardTitle)
                .foregroundStyle(Color.app.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(format.skipBody(prompt))
                .font(Font.app.subhead)
                .foregroundStyle(Color.app.textSecondary)
                .padding(.top, Spacing.xs)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: Spacing.xs) {
                PrimaryButton(Strings.Skip.keep, action: close)
                DangerTextButton(Strings.Skip.use) {
                    usedSkip = true
                    onUseSkip()
                    close()
                }
            }
            .padding(.top, Spacing.lg)
        }
        .multilineTextAlignment(.center)
        .padding(Spacing.lg)
        .frame(width: min(width - Sizes.dialogHorizontalInset, Sizes.dialogMaxWidth))
        .background(Color.app.surface, in: .rounded(Radius.xl))
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private func close() {
        withAnimation(.easeIn(duration: 0.2)) { scrimVisible = false }
        // Let the fade finish, then remove the dialog without the usual slide.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { dismiss() }
        }
    }
}
