import SwiftUI

/// The form's "Color and icon" section (design.md §4.3): 8 color swatches, then a 6-column icon grid.
struct StreakStylePicker: View {
    @Binding var color: StreakColor
    @Binding var icon: String
    /// Called when an icon is tapped, so the form stops guessing the icon from the name.
    var onPickIcon: () -> Void = {}

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: 0) {
                ForEach(StreakColor.allCases) { swatch in
                    Button { color = swatch } label: {
                        Circle()
                            .fill(swatch.main)
                            .frame(width: Sizes.colorSwatch, height: Sizes.colorSwatch)
                            .padding(Sizes.swatchRingGap + Sizes.swatchRing)
                            .overlay {
                                if swatch == color {
                                    Circle().strokeBorder(Color.app.textPrimary, lineWidth: Sizes.swatchRing)
                                }
                            }
                            .frame(minWidth: Sizes.tapTarget, minHeight: Sizes.tapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(swatch.accessibilityName)
                    .accessibilityAddTraits(swatch == color ? .isSelected : [])
                }
            }

            LazyVGrid(columns: columns, spacing: Spacing.xs) {
                ForEach(StreakIcon.all, id: \.self) { symbol in
                    Button {
                        icon = symbol
                        onPickIcon()
                    } label: {
                        Image(systemName: symbol)
                            .font(Font.app.badgeIcon)
                            .foregroundStyle(symbol == icon ? color.main : Color.app.textSecondary)
                            .dynamicTypeSize(...DynamicTypeSize.xxLarge) // fixed-size cells
                            .frame(maxWidth: .infinity, minHeight: Sizes.iconCell)
                            .background(symbol == icon ? color.badge : Color.clear, in: .rounded(Radius.md))
                            .contentShape(.rounded(Radius.md))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Strings.StreakStyle.iconName(symbol))
                    .accessibilityAddTraits(symbol == icon ? .isSelected : [])
                }
            }
        }
        .softHaptic(trigger: color)
        .softHaptic(trigger: icon)
    }
}
