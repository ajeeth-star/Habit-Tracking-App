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
    @Environment(AppSettings.self) private var settings
    @State private var showingEnded = false
    @State private var showingReminderAsk = false
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
        // Catches up on time passing (context.md §11): as each window opens or closes, and at least every minute.
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(store.secondsUntilNextChange()))
                store.refresh()
            }
        }
        // The pretend clock moved (DEBUG): work everything out again.
        .onChange(of: store.clock.offset) { store.refresh() }
        // "Your streak ended" shows once per break, when the app opens or comes back (design.md §4.15).
        .onAppear { showingEnded = dayStreak.state.needsEndedScreen }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            store.refresh()
            if dayStreak.state.needsEndedScreen { showingEnded = true }
        }
        .fullScreenCover(isPresented: $showingEnded, onDismiss: store.markEndedScreenShown) {
            DayStreakEndedView(state: dayStreak.state) { showingEnded = false }
        }
        // Right after the first streak is created: offer reminders, once (context.md §7).
        .onChange(of: store.createdFirstStreak) { _, created in
            guard created else { return }
            store.createdFirstStreak = false
            Task { await askForRemindersIfNeeded() }
        }
        .sheet(isPresented: $showingReminderAsk) {
            ReminderPermissionView(form: dayStreak.state.form) {
                showingReminderAsk = false
                store.refresh() // schedules the reminders if they were just allowed
            }
                .interactiveDismissDisabled()
        }
    }

    /// Not if it was already asked, or reminders are already allowed. Waits for the create form to finish closing.
    /// DEBUG builds: `-askForReminders YES` shows it even if reminders are already allowed (UI tests).
    private func askForRemindersIfNeeded() async {
        var alwaysAsk = false
        #if DEBUG
        alwaysAsk = UserDefaults.standard.bool(forKey: "askForReminders")
        #endif
        guard !settings.askedForReminders else { return }
        let status = await ReminderScheduler.status()
        guard alwaysAsk || status != .authorized else { return }
        try? await Task.sleep(for: .milliseconds(600))
        settings.askedForReminders = true
        showingReminderAsk = true
    }

    /// One tab's navigation stack.
    private func tab<Content: View>(_ tab: AppRouter.Tab, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack { content() }
            .toolbar(.hidden, for: .tabBar)
            .tag(tab)
    }
}
