import SwiftUI

/// A "Popular streaks" chip (design.md §2, §4.2): the streak's icon in a small badge and its name, on a little
/// chunky capsule that presses down with a light haptic.
struct StarterChip: View {
    let preset: StreakPreset
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: preset.icon)
                    .font(Font.app.settingsIcon)
                    .foregroundStyle(preset.color.main)
                    .frame(width: Sizes.starterIcon, height: Sizes.starterIcon)
                    .background(preset.color.badge, in: Circle())
                Text(preset.name)
                    .font(Font.app.cardTitle)
                    .foregroundStyle(Color.app.textPrimary)
                    .fixedSize()
            }
            .padding(.leading, Spacing.xs)
            .padding(.trailing, Spacing.md)
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(StarterChipStyle())
        .accessibilityLabel(preset.name)
        .accessibilityHint(Strings.Starters.hint)
        .accessibilityIdentifier("starter." + preset.name)
    }
}

private struct StarterChipStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Styled(configuration: configuration)
    }

    private struct Styled: View {
        let configuration: Configuration
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(AppSettings.self) private var settings

        private var pressed: Bool { configuration.isPressed && !reduceMotion }

        var body: some View {
            configuration.label
                .background(Color.app.surface, in: Capsule())
                .overlay { Capsule().strokeBorder(Color.app.border, lineWidth: Sizes.borderWidth) }
                .contentShape(Capsule())
                .offset(y: pressed ? Sizes.starterLip : 0)
                .background(alignment: .bottom) {
                    Capsule()
                        .fill(Color.app.border)
                        .offset(y: Sizes.starterLip)
                        .opacity(pressed ? 0 : 1)
                }
                .padding(.bottom, Sizes.starterLip)
                .animation(reduceMotion ? nil : Motion.press, value: pressed)
                .sensoryFeedback(trigger: configuration.isPressed) { _, isDown in
                    settings.vibrations && isDown ? .impact(weight: .light) : nil
                }
        }
    }
}

/// Lays its children out left to right, wrapping onto new lines when a row is full.
struct FlowLayout: Layout {
    var spacing: CGFloat = Spacing.xs

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(width: proposal.width ?? .infinity, subviews: subviews)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(width: bounds.width, subviews: subviews) {
            // Each row is centered.
            var x = bounds.minX + (bounds.width - row.width) / 2
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
