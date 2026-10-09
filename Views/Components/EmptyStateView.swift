import SwiftUI

/// What Home shows before any task exists: a big + and a short invitation.
struct EmptyStateView: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onCreate) {
                Image(systemName: "plus")
                    .font(Font.app.largeIcon)
                    .foregroundStyle(Color.app.textOnBright)
                    .frame(width: Sizes.emptyStateCircle, height: Sizes.emptyStateCircle)
            }
            .buttonStyle(ChunkyCircleStyle())
            .accessibilityLabel(Strings.Home.createTask)

            Text(Strings.Home.emptyTitle)
                .font(Font.app.emptyTitle)
                .foregroundStyle(Color.app.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.lg)

            Text(Strings.Home.emptyBody)
                .font(Font.app.subhead)
                .foregroundStyle(Color.app.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: Sizes.emptyStateTextMaxWidth)
                .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
    }
}

/// The empty state's big round + : a flame circle with a lip that presses down like a chunky button.
private struct ChunkyCircleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Styled(configuration: configuration)
    }

    private struct Styled: View {
        let configuration: Configuration
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(AppSettings.self) private var settings

        var body: some View {
            let pressed = configuration.isPressed && !reduceMotion
            configuration.label
                .background(Color.app.flame, in: Circle())
                .offset(y: pressed ? Sizes.buttonLip : 0)
                .background {
                    Circle().fill(Color.app.flameLip).offset(y: Sizes.buttonLip)
                }
                .padding(.bottom, Sizes.buttonLip)
                .animation(reduceMotion ? nil : Motion.press, value: configuration.isPressed)
                .sensoryFeedback(trigger: configuration.isPressed) { _, isDown in
                    settings.vibrations && isDown ? .impact(weight: .light) : nil
                }
        }
    }
}
