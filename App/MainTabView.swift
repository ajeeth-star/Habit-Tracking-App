import SwiftUI

/// The tab bar (design.md §4.0): Today, Habits, History, Settings. Each tab has its own navigation
/// stack, so going back never jumps tabs and each tab stays where it was.
struct MainTabView: View {
    /// How each tab starts out. The app uses the defaults; the Design Gallery opens specific states.
    struct StartState {
        var showsDone = false
        var showsArchived = false
        var historyFilter: String?
        var notificationsOff: Bool?
    }

    var start = StartState()
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            NavigationStack { HomeView(showsDone: start.showsDone) }
                .tabItem { Label(Strings.Tabs.today, systemImage: "sun.max.fill") }
                .tag(AppRouter.Tab.today)
            NavigationStack { HabitsView(showsArchived: start.showsArchived) }
                .tabItem { Label(Strings.Tabs.habits, systemImage: "flame.fill") }
                .tag(AppRouter.Tab.habits)
            NavigationStack { AllHistoryView(filter: start.historyFilter) }
                .tabItem { Label(Strings.Tabs.history, systemImage: "photo.on.rectangle") }
                .tag(AppRouter.Tab.history)
            NavigationStack { SettingsView(notificationsOffOverride: start.notificationsOff) }
                .tabItem { Label(Strings.Tabs.settings, systemImage: "gearshape.fill") }
                .tag(AppRouter.Tab.settings)
        }
        // Icons and labels use the accent's text/icon shade, so they read on the dark tab bar too.
        .tint(Color.app.accentText)
    }
}
