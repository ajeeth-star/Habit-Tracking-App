import SwiftUI

/// The photo just taken, with Retake / Submit (design.md §4.7). Always black with white controls.
struct PhotoPreviewView: View {
    let taskName: String
    let closesAt: TimeOfDay
    /// The captured photo. Nil shows a placeholder (always, for now).
    var image: Image?
    let onRetake: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        ZStack {
            Color.app.cameraBackground.ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                Text(Strings.Camera.header(taskName, Formatters.current.time(closesAt)))
                    .font(Font.app.subhead)
                    .monospacedDigit()
                    .foregroundStyle(Color.app.cameraForeground)
                    .frame(minHeight: Sizes.tapTarget)

                photo
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                AdaptiveStack {
                    SecondaryButton(Strings.Camera.retake, onDark: true, action: onRetake)
                    PrimaryButton(Strings.Camera.submit, action: onSubmit)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
        }
        // Always black with white controls. The dark look stays local to this screen (a preferredColorScheme
        // would leak into whatever the same full-screen presentation shows next), and the status bar is
        // hidden, like the system Camera app.
        .environment(\.colorScheme, .dark)
        .statusBarHidden()
    }

    @ViewBuilder private var photo: some View {
        if let image {
            image
                .resizable()
                .scaledToFit()
        } else {
            PhotoThumbnail()
                .padding(.horizontal, Spacing.lg)
        }
    }
}
