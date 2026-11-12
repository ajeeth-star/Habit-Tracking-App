import SwiftUI

/// The custom tab bar (design.md §4.0): Today, Streaks, Progress, and Flame. Every icon is always in its tab's own
/// color; the selected one sits in a rounded square with its label underneath.
struct AppTabBar: View {
    @Binding var selection: AppRouter.Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppRouter.Tab.allCases, id: \.self) { tab in
                TabButton(tab: tab, isSelected: selection == tab) { selection = tab }
            }
        }
        .frame(height: Sizes.tabBarHeight)
        .background {
            Color.app.surface.ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.app.border)
                .frame(height: Sizes.borderWidth)
        }
        // Fixed-size icons and a fixed-height bar: labels stop growing before they'd clip.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }
}

extension AppRouter.Tab {
    var title: String {
        switch self {
        case .today: Strings.Tabs.today
        case .streaks: Strings.Tabs.streaks
        case .progress: Strings.Tabs.progress
        case .flame: Strings.Tabs.flame
        }
    }

    var icon: String {
        switch self {
        case .today: "sun.max.fill"
        case .streaks: "checklist"
        case .progress: "chart.bar.fill"
        case .flame: "flame.fill"
        }
    }

    /// Each tab's own color, used for its icon whether selected or not.
    var color: Color {
        switch self {
        case .today: Color.app.gold
        case .streaks: Color.app.info
        case .progress: Color.app.success
        case .flame: Color.app.flame
        }
    }
}

private struct TabButton: View {
    let tab: AppRouter.Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxs) {
                Image(systemName: tab.icon)
                    .font(Font.app.tabIcon)
                    .foregroundStyle(tab.color)
                    .opacity(isSelected ? 1 : Sizes.tabUnselectedOpacity)
                    .frame(width: Sizes.tabSelection, height: Sizes.tabSelection)
                    .background {
                        // The selected tab's icon sits in a rounded square with a border in its color.
                        if isSelected {
                            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                .fill(tab.color.opacity(Sizes.tabSelectedFillOpacity))
                            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                .strokeBorder(tab.color, lineWidth: Sizes.emphasisStroke)
                        }
                    }
                if isSelected {
                    Text(tab.title)
                        .font(Font.app.caption)
                        .foregroundStyle(tab.color)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("tab." + tab.title)
    }
}
