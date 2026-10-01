import SwiftUI

/// Lays its children out side by side, but stacks them vertically at accessibility text sizes,
/// so text wraps instead of clipping (design.md §5). Used for paired buttons, stat tiles,
/// the time-window boxes, and a card's name + status pill.
struct AdaptiveStack<Content: View>: View {
    var horizontalAlignment: HorizontalAlignment = .center
    var verticalAlignment: VerticalAlignment = .center
    var spacing: CGFloat = Spacing.xs
    @ViewBuilder let content: Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: horizontalAlignment, spacing: spacing))
            : AnyLayout(HStackLayout(alignment: verticalAlignment, spacing: spacing))
        layout { content }
    }
}
