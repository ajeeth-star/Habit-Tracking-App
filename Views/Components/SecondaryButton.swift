import SwiftUI

/// A quieter action: surface fill with a hairline outline.
/// `onDark` is the photo-preview variant: translucent white fill and white label, to read on black.
struct SecondaryButton: View {
    let title: String
    var systemImage: String?
    var onDark = false
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, onDark: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.onDark = onDark
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ButtonLabel(title: title, systemImage: systemImage)
        }
        .buttonStyle(onDark
            ? AppButtonStyle(
                fill: Color.app.cameraButtonFill,
                label: Color.app.cameraForeground,
                disabledFill: Color.app.cameraButtonFill,
                outline: nil)
            : AppButtonStyle(
                fill: Color.app.surface,
                label: Color.app.textPrimary,
                disabledFill: Color.app.surface,
                outline: Color.app.separator))
    }
}
