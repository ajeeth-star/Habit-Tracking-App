import SwiftUI

/// A small muted box with a label on top and a value below, e.g. "Streak" / "3w 2d".
struct StatTile<Value: View>: View {
    let label: String
    @ViewBuilder let value: Value

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(label)
                .font(Font.app.caption)
                .foregroundStyle(Color.app.textSecondary)
            value
                .font(Font.app.statValue)
                .foregroundStyle(Color.app.textPrimary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(Color.app.surfaceRaised, in: .rounded(Radius.md))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(Color.app.border, lineWidth: Sizes.borderWidth)
        }
        .accessibilityElement(children: .combine)
    }
}

extension StatTile where Value == Text {
    init(label: String, value: String) {
        self.label = label
        self.value = Text(value)
    }
}
