import SwiftUI

/// The custom tab bar (design.md §4.0): History on the left, a raised round Today button in the
/// middle, Streaks on the right.
struct AppTabBar: View {
    @Binding var selection: AppRouter.Tab

    var body: some View {
        HStack(spacing: 0) {
            SideTab(title: Strings.Tabs.history, icon: "clock.arrow.circlepath",
                    isSelected: selection == .history) { selection = .history }
            // Room for the center button, which sits on top of the bar.
            Color.clear.frame(width: Sizes.centerTabButton + 2 * Sizes.centerTabRing)
            SideTab(title: Strings.Tabs.streaks, icon: "flame.fill",
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
        .overlay(alignment: .top) {
            CenterTodayButton(isSelected: selection == .today) { selection = .today }
                // The circle's top sits `centerTabRise` above the bar; its ring adds a little more.
                .offset(y: -(Sizes.centerTabRise + Sizes.centerTabRing))
        }
        // Fixed-size icons and a fixed-height bar: labels stop growing before they'd clip.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }
}

private struct SideTab: View {
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

private struct CenterTodayButton: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "sun.max.fill")
                .font(Font.app.centerTabIcon)
                .foregroundStyle(Color.app.onAccent)
                .frame(width: Sizes.centerTabButton, height: Sizes.centerTabButton)
                .background {
                    Circle().fill(LinearGradient(colors: [Color.app.accent, Color.app.accentLight],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                }
        }
        .buttonStyle(CenterButtonStyle())
        // The background-colored ring makes the button look cut out of the bar.
        .padding(Sizes.centerTabRing)
        .background(Color.app.background, in: Circle())
        .accessibilityLabel(Strings.Tabs.today)
        .accessibilityIdentifier("tab." + Strings.Tabs.today)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Shrinks a little while pressed, with a light haptic (unless Vibrations is off or Reduce Motion is on).
private struct CenterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Pressed(configuration: configuration)
    }

    private struct Pressed: View {
        let configuration: Configuration
        @Environment(AppSettings.self) private var settings
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            configuration.label
                .scaleEffect(configuration.isPressed && !reduceMotion ? Motion.pressedScale : 1)
                .animation(reduceMotion ? nil : Motion.standard, value: configuration.isPressed)
                .sensoryFeedback(trigger: configuration.isPressed) { _, pressed in
                    settings.vibrations && pressed ? .impact(weight: .light) : nil
                }
        }
    }
}
