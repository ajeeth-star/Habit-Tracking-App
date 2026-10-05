import SwiftUI

/// The custom tab bar (design.md §4.0): Today on the left, Streaks on the right.
struct AppTabBar: View {
    @Binding var selection: AppRouter.Tab

    var body: some View {
        HStack(spacing: 0) {
            TabButton(title: Strings.Tabs.today, icon: "sun.max.fill",
                      isSelected: selection == .today) { selection = .today }
            TabButton(title: Strings.Tabs.streaks, icon: "flame.fill",
                      isSelected: selection == .streaks) { selection = .streaks }
        }
        .frame(height: Sizes.tabBarHeight)
        .background {
            Color.app.surface.ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.app.separator)
                .frame(height: Sizes.hairline)
        }
        // Fixed-size icons and a fixed-height bar: labels stop growing before they'd clip.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }
}

private struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(Font.app.tabIcon)
                Text(title)
                    .font(Font.app.caption)
            }
            .foregroundStyle(isSelected ? Color.app.accentText : Color.app.textTertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("tab." + title)
    }
}
