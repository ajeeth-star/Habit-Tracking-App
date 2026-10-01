import SwiftUI

/// A secondary-looking button with a red label. Used only for "Use skip".
struct DangerTextButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ButtonLabel(title: title, systemImage: nil)
        }
        .buttonStyle(AppButtonStyle(
            fill: Color.app.surface,
            label: Color.app.danger,
            disabledFill: Color.app.surface,
            outline: Color.app.separator
        ))
    }
}
