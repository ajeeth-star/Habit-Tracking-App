import SwiftUI

/// The in-app camera (design.md §4.6). Always black with white controls. There is deliberately no
/// photo-library button. This phase draws the screen only; the live camera arrives in the check-in phase.
struct CameraView: View {
    let taskName: String
    let closesAt: TimeOfDay
    /// Shows "The window closed at …" (in the real app the camera then closes itself).
    var windowClosed = false
    let onClose: () -> Void
    let onCapture: () -> Void

    private let format = Formatters.current

    var body: some View {
        ZStack {
            Color.app.cameraBackground.ignoresSafeArea()

            viewfinder

            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomBar
            }
        }
        .foregroundStyle(Color.app.cameraForeground)
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder private var viewfinder: some View {
        if windowClosed {
            Text(Strings.Camera.windowClosed(format.time(closesAt)))
                .font(Font.app.subhead)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
        } else {
            #if DEBUG && targetEnvironment(simulator)
            // The simulator has no camera.
            Button(action: onCapture) {
                Text(Strings.Camera.useSamplePhoto)
                    .font(Font.app.button)
                    .padding(.horizontal, Spacing.md)
                    .frame(minHeight: Sizes.buttonHeight)
                    .background(Color.app.cameraButtonFill, in: .rounded(Radius.md))
            }
            #endif
        }
    }

    private var topBar: some View {
        ZStack {
            Text(Strings.Camera.header(taskName, format.time(closesAt)))
                .font(Font.app.subhead)
                .monospacedDigit()
                .padding(.horizontal, Sizes.tapTarget + Spacing.xs)
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(Font.app.button)
                        .frame(width: Sizes.tapTarget, height: Sizes.tapTarget)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Strings.Camera.close)
                Spacer()
            }
        }
        .padding(.horizontal, Spacing.xs)
    }

    private var bottomBar: some View {
        ZStack {
            Button(action: onCapture) {
                Circle()
                    .frame(width: Sizes.shutterInner, height: Sizes.shutterInner)
                    .padding(Sizes.shutterGap + Sizes.shutterRing)
                    .overlay {
                        Circle().strokeBorder(lineWidth: Sizes.shutterRing)
                    }
            }
            .disabled(windowClosed)
            .opacity(windowClosed ? 0.4 : 1)
            .accessibilityLabel(Strings.Camera.takePhoto)

            HStack {
                Spacer()
                Button {} label: {
                    Image(systemName: "camera.rotate")
                        .font(Font.app.screenTitle)
                        .frame(width: Sizes.tapTarget, height: Sizes.tapTarget)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Strings.Camera.switchCamera)
            }
            .padding(.horizontal, Spacing.lg)
        }
        .padding(.bottom, Spacing.lg)
    }
}
