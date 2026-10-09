import SwiftUI

/// A centered confirmation dialog over a dim scrim (design.md §2, layout in §4.5). Not Apple's alert,
/// so the **safe choice is always the highlighted first button**. Present it with `.dialogCover`.
struct AppDialog: View {
    enum ActionStyle {
        /// `SecondaryButton`: "Archive", "Continue"
        case neutral
        /// `DangerTextButton`: "Use skip", "Delete", "Delete everything"
        case destructive
    }

    let title: String
    var message: String?
    var safeTitle = Strings.Dialog.cancel
    let actionTitle: String
    var actionStyle = ActionStyle.destructive
    /// Played on the action, if Settings → Vibrations is on.
    var actionHaptic: SensoryFeedback?
    /// Played on the action, if Settings → Sounds is on.
    var actionSound: SoundPlayer.Sound?
    /// False keeps the dialog up after the action, so the caller can swap in a follow-up question.
    var closesOnAction = true
    let onAction: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @State private var visible = false
    @State private var actionCount = 0

    var body: some View {
        ZStack {
            Color.app.scrim
                .ignoresSafeArea()
                // Tapping outside counts as the safe choice.
                .onTapGesture(perform: close)
                .accessibilityHidden(true)

            GeometryReader { proxy in
                // At very large text sizes the dialog can be taller than the screen; then it scrolls.
                ViewThatFits(in: .vertical) {
                    card(width: proxy.size.width)
                    ScrollView {
                        card(width: proxy.size.width)
                            .padding(.vertical, Spacing.lg)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .opacity(visible ? 1 : 0)
        .onAppear {
            withAnimation(Motion.standard) { visible = true }
        }
        .sensoryFeedback(trigger: actionCount) { _, _ in
            settings.vibrations ? actionHaptic : nil
        }
    }

    private func card(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(Font.app.cardTitle)
                .foregroundStyle(Color.app.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if let message {
                Text(message)
                    .font(Font.app.subhead)
                    .foregroundStyle(Color.app.textSecondary)
                    .padding(.top, Spacing.xs)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: Spacing.xs) {
                ChunkyButton(safeTitle, action: close)
                switch actionStyle {
                case .neutral: ChunkyButton(style: .secondary, actionTitle, action: act)
                case .destructive: ChunkyButton(style: .danger, actionTitle, action: act)
                }
            }
            .padding(.top, Spacing.lg)
        }
        .multilineTextAlignment(.center)
        .padding(Spacing.lg)
        .frame(width: min(width - Sizes.dialogHorizontalInset, Sizes.dialogMaxWidth))
        .background(Color.app.surfaceRaised, in: .rounded(Radius.xl))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                .strokeBorder(Color.app.border, lineWidth: Sizes.borderWidth)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private func act() {
        actionCount += 1
        if let actionSound { SoundPlayer.shared.play(actionSound, enabled: settings.sounds) }
        onAction()
        if closesOnAction { close() }
    }

    private func close() {
        withAnimation(Motion.standard) { visible = false }
        // Let the fade finish, then remove the dialog without the usual slide.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withoutAnimation { dismiss() }
        }
    }
}

/// Runs a state change with no animation: used to present and remove dialogs without a slide.
func withoutAnimation(_ change: () -> Void) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction, change)
}

extension View {
    /// Presents a dialog full screen with a see-through background, so the screen stays visible under
    /// the scrim. Set `isPresented` inside `withoutAnimation { }` so it fades in instead of sliding up.
    func dialogCover<Dialog: View>(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil,
                                   @ViewBuilder dialog: @escaping () -> Dialog) -> some View {
        fullScreenCover(isPresented: isPresented, onDismiss: onDismiss) {
            dialog().presentationBackground(.clear)
        }
    }
}
