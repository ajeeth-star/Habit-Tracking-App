import SwiftUI

/// A Progress tab stat (design.md §2): an icon in its own color, a big number, and its label, on a chunky card.
/// The number counts up from 0 whenever `counting` turns on.
struct ProgressStatCard: View {
    let icon: String
    let color: Color
    let label: String
    /// The number shown; nil shows "—".
    let value: Int?
    /// Turns the number into text, e.g. 86 → "86%".
    var text: (Int) -> String = { "\($0)" }
    var counting = true

    var body: some View {
        let shown = counting ? value : value.map { _ in 0 }
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(Font.app.badgeIcon)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(shown.map(text) ?? Strings.Progress.noRate)
                .font(Font.app.statNumber)
                .foregroundStyle(Color.app.textPrimary)
                .contentTransition(.numericText(value: Double(shown ?? 0)))
                .padding(.top, Spacing.xxs)
            Text(label)
                .font(Font.app.caption)
                .foregroundStyle(Color.app.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .chunkyCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value.map(text) ?? Strings.Progress.noRate)
    }
}

/// The welcome's progress dots (design.md §2): the current page is a wider flame capsule.
struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.app.flame : Color.app.surfaceMuted)
                    .frame(width: index == current ? Sizes.pageDotCurrent : Sizes.pageDot, height: Sizes.pageDot)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Welcome.page(current + 1, count))
    }
}
