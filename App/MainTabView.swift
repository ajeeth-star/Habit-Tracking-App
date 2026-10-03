import SwiftUI

/// The app's three tabs (design.md §4.0) with the custom tab bar underneath. Every tab stays alive
/// with its own navigation stack, so switching tabs keeps each one where it was.
struct MainTabView: View {
    /// How each tab starts out. The app uses the defaults; the Design Gallery opens specific states.
    struct StartState {
        var showsDone = false
        var showsArchived = false
        var historyFilter: String?
    }

    var start = StartState()
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        VStack(spacing: 0) {
            // Apple's tab container keeps every tab alive and shows VoiceOver only the current one;
            // its own bar is hidden in favor of `AppTabBar`.
            TabView(selection: $router.selectedTab) {
                tab(.history) { AllHistoryView(filter: start.historyFilter) }
                tab(.today) { HomeView(showsDone: start.showsDone) }
                tab(.streaks) { HabitsView(showsArchived: start.showsArchived) }
            }
            AppTabBar(selection: $router.selectedTab)
        }
        // The keyboard covers the tab bar rather than pushing it up.
        .ignoresSafeArea(.keyboard)
    }

    /// One tab's navigation stack.
    private func tab<Content: View>(_ tab: AppRouter.Tab, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack { content() }
            .toolbar(.hidden, for: .tabBar)
            .tag(tab)
    }
}
