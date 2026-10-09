import SwiftUI

/// The app's button (design.md §2): a colored face with a darker 4pt "lip" under it. Pressing pushes
/// the face down onto the lip, with a light haptic. Labels show in ALL CAPS.
struct ChunkyButton: View {
    enum Style: Equatable {
        /// Flame fill, dark label: the main action.
        case primary
        /// Green fill, dark label.
        case success
        /// Surface fill with a border, blue label.
        case secondary
        /// Surface fill with a border, red label.
        case danger
        /// White fill, label in the given color: Check in on a hero card.
        case white(label: Color)
        /// Translucent white on black: the photo preview's Retake.
        case onDark
    }

    let title: String
    var systemImage: String?
    var style: Style = .primary
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.action = action
    }

    /// Lets call sites lead with the style: `ChunkyButton(style: .secondary, "Use a skip") { … }`.
    init(style: Style, _ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.init(title, systemImage: systemImage, style: style, action: action)
    }

    var body: some View {
        Button(action: action) {
            ButtonLabel(title: title, systemImage: systemImage)
        }
        .buttonStyle(ChunkyButtonStyle(style: style))
        // VoiceOver reads the sentence-case title, not the capitals.
        .accessibilityLabel(title)
    }
}

/// Icon + title, centered, in ALL CAPS.
struct ButtonLabel: View {
    let title: String
    let systemImage: String?

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .fontWeight(.heavy)
            }
            Text(title)
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(Font.app.button)
        .capsLabel()
        .multilineTextAlignment(.center)
    }
}

/// The face-and-lip look and the press-down behavior.
struct ChunkyButtonStyle: ButtonStyle {
    let style: ChunkyButton.Style

    func makeBody(configuration: Configuration) -> some View {
        Styled(configuration: configuration, style: style)
    }

    private struct Styled: View {
        let configuration: Configuration
        let style: ChunkyButton.Style
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(AppSettings.self) private var settings

        private struct Look {
            var fill: Color
            var lip: Color
            var label: Color
            var outline: Color?
        }

        private var look: Look {
            guard isEnabled else {
                return Look(fill: Color.app.disabled, lip: Color.app.disabledLip, label: Color.app.textTertiary)
            }
            switch style {
            case .primary:
                return Look(fill: Color.app.flame, lip: Color.app.flameLip, label: Color.app.textOnBright)
            case .success:
                return Look(fill: Color.app.success, lip: Color.app.successLip, label: Color.app.textOnBright)
            case .secondary:
                return Look(fill: Color.app.surface, lip: Color.app.border, label: Color.app.info, outline: Color.app.border)
            case .danger:
                return Look(fill: Color.app.surface, lip: Color.app.border, label: Color.app.danger, outline: Color.app.border)
            case .white(let label):
                return Look(fill: Color.app.whiteButton, lip: Color.app.whiteButtonLip, label: label)
            case .onDark:
                return Look(fill: Color.app.cameraButtonFill, lip: Color.app.cameraButtonFill,
                            label: Color.app.cameraForeground)
            }
        }

        private var pressed: Bool { configuration.isPressed && isEnabled }

        var body: some View {
            let look = look
            configuration.label
                .foregroundStyle(look.label)
                .padding(.horizontal, Spacing.sm)
                .frame(maxWidth: .infinity, minHeight: Sizes.buttonHeight)
                .background(look.fill, in: .rounded(Radius.lg))
                .overlay {
                    if let outline = look.outline {
                        RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                            .strokeBorder(outline, lineWidth: Sizes.borderWidth)
                    }
                }
                .contentShape(.rounded(Radius.lg))
                // Pushed down onto the lip while pressed.
                .offset(y: pressed && !reduceMotion ? Sizes.buttonLip : 0)
                .background(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                        .fill(look.lip)
                        .offset(y: Sizes.buttonLip)
                        .opacity(pressed && !reduceMotion ? 0 : 1)
                }
                .padding(.bottom, Sizes.buttonLip)
                .animation(reduceMotion ? nil : Motion.press, value: pressed)
                .sensoryFeedback(trigger: pressed) { _, isDown in
                    settings.vibrations && isDown ? .impact(weight: .light) : nil
                }
        }
    }
}
