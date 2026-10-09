import SwiftUI

/// A glossy candy-bar progress bar (design.md §1.5): 16pt, fully rounded, a colored fill with a
/// lighter stripe along its top. Nothing on screen uses one yet; it's ready for the rewards phase.
struct ProgressBar: View {
    /// 0…1
    let progress: Double
    var color = Color.app.flame

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width * min(max(progress, 0), 1)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.app.track)
                if width > 0 {
                    Capsule()
                        .fill(color)
                        .frame(width: max(width, Sizes.progressBar))
                        .overlay(alignment: .top) {
                            // The glossy stripe, inset from the ends and the top.
                            Capsule()
                                .fill(Color.app.highlight)
                                .frame(height: Sizes.progressHighlight)
                                .padding(.horizontal, Sizes.progressBar / 2)
                                .padding(.top, Sizes.progressHighlight / 2 + 1)
                        }
                }
            }
        }
        .frame(height: Sizes.progressBar)
        .accessibilityElement()
        .accessibilityValue("\(Int((progress * 100).rounded()))%")
    }
}
