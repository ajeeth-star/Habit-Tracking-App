import SwiftUI

/// The app's two tabs (design.md §4.0) with the custom tab bar underneath. Every tab stays alive
/// with its own navigation stack, so switching tabs keeps each one where it was.
struct MainTabView: View {
    /// How each tab starts out. The app uses the defaults; the Design Gallery opens specific states.
    struct StartState {
        var showsDone = false
        var showsArchived = false
        /// Fixes which line the speech bubble picks (nil: random).
        var bubbleVariant: Int?
    }

    var start = StartState()
    @Environment(AppRouter.self) private var router
    @Environment(TaskStore.self) private var store
    @Environment(DayStreakStore.self) private var dayStreak
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingEnded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        @Bindable var router = router
        VStack(spacing: 0) {
            // Apple's tab container keeps every tab alive and shows VoiceOver only the current one;
            // its own bar is hidden in favor of `AppTabBar`.
            TabView(selection: $router.selectedTab) {
                tab(.today) { HomeView(showsDone: start.showsDone, bubbleVariant: start.bubbleVariant) }
                tab(.streaks) { HabitsView(showsArchived: start.showsArchived) }
            }
            if !router.hidesTabBar {
                AppTabBar(selection: $router.selectedTab)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(reduceMotion ? nil : Motion.standard, value: router.hidesTabBar)
        // The keyboard covers the tab bar rather than pushing it up.
        .ignoresSafeArea(.keyboard)
        // Keeps the day streak up to date: right away when the tasks change, and as windows close.
        .task(id: store.tasks) {
            while !Task.isCancelled {
                dayStreak.update(tasks: store.tasks, now: store.now())
                try? await Task.sleep(for: .seconds(20))
            }
        }
        // "Your streak ended" shows once per break, when the app opens or comes back (design.md §4.15).
        .onAppear { showingEnded = dayStreak.state.needsEndedScreen }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, dayStreak.state.needsEndedScreen { showingEnded = true }
        }
        .fullScreenCover(isPresented: $showingEnded, onDismiss: dayStreak.markEndedScreenShown) {
            DayStreakEndedView(state: dayStreak.state) { showingEnded = false }
        }
    }

    /// One tab's navigation stack.
    private func tab<Content: View>(_ tab: AppRouter.Tab, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack { content() }
            .toolbar(.hidden, for: .tabBar)
            .tag(tab)
    }
}
