import SwiftUI

/// A capsule filter button, e.g. the habit chips on the History tab.
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    /// The selected fill: a streak's color for its chip, the app accent for "All".
    var selectedFill = Color.app.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Font.app.subhead)
                .foregroundStyle(isSelected ? Color.app.onAccent : Color.app.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background {
                    if isSelected {
                        Capsule().fill(selectedFill)
                    } else {
                        Capsule().fill(Color.app.surface)
                            .overlay { Capsule().strokeBorder(Color.app.separator, lineWidth: Sizes.hairline) }
                    }
                }
                .frame(minHeight: Sizes.tapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
