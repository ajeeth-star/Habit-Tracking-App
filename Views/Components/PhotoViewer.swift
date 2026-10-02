import SwiftUI

/// One check-in photo, full screen on black, with its date and time and a close button.
/// Used by both History screens.
struct PhotoViewer: View {
    let date: Date
    var image: Image?
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.app.cameraBackground.ignoresSafeArea()
            PhotoThumbnail(image: image)
                .padding(.horizontal, Spacing.lg)
            VStack {
                ZStack {
                    Text(Formatters.current.photoDate(date))
                        .font(Font.app.subhead)
                        .monospacedDigit()
                    HStack {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(Font.app.button)
                                .frame(width: Sizes.tapTarget, height: Sizes.tapTarget)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel(Strings.History.close)
                        Spacer()
                    }
                }
                .padding(.horizontal, Spacing.xs)
                Spacer()
            }
        }
        .foregroundStyle(Color.app.cameraForeground)
        // Always black with white controls; the dark look stays local to this screen.
        .environment(\.colorScheme, .dark)
        .statusBarHidden()
    }
}
