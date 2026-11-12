import SwiftUI

/// The app's four tabs (design.md §4.0) with the custom tab bar underneath. Every tab stays alive
/// with its own navigation stack, so switching tabs keeps each one where it was. A fresh install
/// starts with the welcome screens (design.md §4.20).
struct MainTabView: View {
    /// How each tab starts out. The app uses the defaults; the Design Gallery opens specific states.
    struct StartState {
        var showsArchived = false
        /// Fixes which line the speech bubble picks (nil: random).
        var bubbleVariant: Int?
        /// The Progress tab's month: 0 is this month, -1 last month.
        var progressMonthOffset = 0
    }

    var start = StartState()
    @Environment(AppRouter.self) private var router
    @Environment(TaskStore.self) private var store
    @Environment(DayStreakStore.self) private var dayStreak
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppSettings.self) private var settings
    /// The one full-screen cover the app opens with: "streak ended" or the welcome. One cover for both, because
    /// two cover modifiers in the same place don't reliably both show.
    @State private var cover: Cover?
    /// The cover being shown, kept until it has closed (so closing "streak ended" can mark it shown).
    @State private var presentedCover: Cover?
    @State private var showingReminderAsk = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        @Bindable var router = router
        VStack(spacing: 0) {
            // Apple's tab container keeps every tab alive and shows VoiceOver only the current one;
            // its own bar is hidden in favor of `AppTabBar`.
            TabView(selection: $router.selectedTab) {
                tab(.today) { HomeView(bubbleVariant: start.bubbleVariant) }
                tab(.streaks) { HabitsView(showsArchived: start.showsArchived) }
                tab(.progress) { ProgressTabView(monthOffset: start.progressMonthOffset) }
                tab(.flame) { FlameView() }
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
        .task {
            // After the first frame: a cover asked for while the window is still appearing can be dropped.
            await Task.yield()
            if dayStreak.state.needsEndedScreen { present(.ended) }
            showWelcomeIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { BackgroundRefresh.schedule() }
            guard phase == .active else { return }
            store.refresh()
            if dayStreak.state.needsEndedScreen, cover == nil { present(.ended) }
        }
        .fullScreenCover(item: $cover, onDismiss: coverClosed) { cover in
            switch cover {
            case .ended:
                DayStreakEndedView(state: dayStreak.state) { self.cover = nil }
            case .welcome:
                WelcomeView {
                    settings.seenWelcome = true
                    self.cover = nil
                }
            }
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

    private enum Cover: Identifiable {
        case ended, welcome
        var id: Self { self }
    }

    private func present(_ newCover: Cover) {
        presentedCover = newCover
        cover = newCover
    }

    /// "Your streak ended" shows once per break: once it has closed, it's marked as shown.
    private func coverClosed() {
        if presentedCover == .ended { store.markEndedScreenShown() }
        presentedCover = nil
    }

    /// The welcome shows once, on a fresh install's first open (saved data with no streaks yet). An install that
    /// already has streaks counts it as seen. The Design Gallery and sample-data UI tests never show it here.
    private func showWelcomeIfNeeded() {
        guard !settings.seenWelcome, !store.isSample, cover == nil else { return }
        if store.tasks.isEmpty {
            present(.welcome)
        } else {
            settings.seenWelcome = true
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
