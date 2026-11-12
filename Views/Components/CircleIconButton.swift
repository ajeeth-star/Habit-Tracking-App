import SwiftUI

/// A round chunky button (design.md §2): a 44pt `surfaceRaised` circle with a 2pt border and a 3pt lip, holding
/// one icon. Pressing pushes it down onto the lip, with a light haptic. Today's gear and + use it.
struct CircleIconButton: View {
    let systemImage: String
    var color = Color.app.textSecondary
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(Font.app.circleButtonIcon)
                .foregroundStyle(color)
        }
        .buttonStyle(CircleIconButtonStyle())
        .accessibilityLabel(label)
    }
}

private struct CircleIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Styled(configuration: configuration)
    }

    private struct Styled: View {
        let configuration: Configuration
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(AppSettings.self) private var settings

        private var pressed: Bool { configuration.isPressed && !reduceMotion }

        var body: some View {
            configuration.label
                .frame(width: Sizes.circleButton, height: Sizes.circleButton)
                .background(Color.app.surfaceRaised, in: Circle())
                .overlay { Circle().strokeBorder(Color.app.border, lineWidth: Sizes.borderWidth) }
                .contentShape(Circle())
                // Pushed down onto the lip while pressed.
                .offset(y: pressed ? Sizes.circleButtonLip : 0)
                .background(alignment: .bottom) {
                    Circle()
                        .fill(Color.app.border)
                        .frame(width: Sizes.circleButton, height: Sizes.circleButton)
                        .offset(y: Sizes.circleButtonLip)
                        .opacity(pressed ? 0 : 1)
                }
                .padding(.bottom, Sizes.circleButtonLip)
                .animation(reduceMotion ? nil : Motion.press, value: pressed)
                .sensoryFeedback(trigger: configuration.isPressed) { _, isDown in
                    settings.vibrations && isDown ? .impact(weight: .light) : nil
                }
        }
    }
}
