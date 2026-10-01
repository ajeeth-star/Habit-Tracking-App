import SwiftUI

/// The one most important action on a screen: accent fill, white label.
struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    /// The hero-card variant: white fill, accent label.
    var inverted = false
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, inverted: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.inverted = inverted
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ButtonLabel(title: title, systemImage: systemImage)
        }
        .buttonStyle(AppButtonStyle(
            fill: inverted ? Color.app.onAccent : Color.app.accent,
            label: inverted ? Color.app.accent : Color.app.onAccent,
            disabledFill: Color.app.surfaceMuted,
            outline: nil
        ))
    }
}

/// Icon + title, centered. Shared by all three button types.
struct ButtonLabel: View {
    let title: String
    let systemImage: String?

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(Font.app.button)
        .multilineTextAlignment(.center)
    }
}

/// The 50pt, full-width, rounded look shared by `PrimaryButton`, `SecondaryButton`, and `DangerTextButton`.
struct AppButtonStyle: ButtonStyle {
    let fill: Color
    let label: Color
    let disabledFill: Color
    let outline: Color?

    func makeBody(configuration: Configuration) -> some View {
        StyledBody(configuration: configuration, style: self)
    }

    private struct StyledBody: View {
        let configuration: Configuration
        let style: AppButtonStyle
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .foregroundStyle(isEnabled ? style.label : Color.app.textTertiary)
                .padding(.horizontal, Spacing.sm)
                .frame(maxWidth: .infinity, minHeight: Sizes.buttonHeight)
                .background(isEnabled ? style.fill : style.disabledFill, in: .rounded(Radius.md))
                .overlay {
                    if let outline = style.outline {
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .strokeBorder(outline, lineWidth: Sizes.hairline)
                    }
                }
                .contentShape(.rounded(Radius.md))
                .opacity(configuration.isPressed ? 0.7 : 1)
        }
    }
}
