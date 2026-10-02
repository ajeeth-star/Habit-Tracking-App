import SwiftUI

extension View {
    /// Screens without a navigation bar scroll their content up under the clock and battery icons.
    /// This puts a strip of `background` behind the status bar so the two never overlap.
    func statusBarBackdrop() -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            Color.clear
                .frame(height: 0)
                .background(Color.app.background) // a background extends into the safe area above it
        }
    }
}
