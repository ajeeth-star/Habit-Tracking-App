import SwiftData
import SwiftUI
import UserNotifications

@main
struct HabitApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var settings: AppSettings
    @State private var store: TaskStore
    @State private var dayStreak: DayStreakStore

    @MainActor
    init() {
        let settings = AppSettings()
        let (store, dayStreak) = Self.makeStores(settings: settings)
        store.dayStreak = dayStreak
        // Up to date before the first frame, so the flame and the "streak ended" screen are right at launch.
        store.refresh()
        _settings = State(initialValue: settings)
        _store = State(initialValue: store)
        _dayStreak = State(initialValue: dayStreak)
    }

    /// The saved data. DEBUG builds also understand these launch options (used by UI tests):
    /// - `-sampleMode YES`: the old in-memory sample data at Thursday 6:40 PM instead of saved data (no reminders);
    /// - `-resetData YES`: erase all saved data, go back to the real time, and forget the reminder question;
    /// - `-pretendNow "2026-10-05 17:30"`: start the pretend clock at that local time;
    /// - `-fillSampleData YES`: add a few weeks of sample streaks (like Settings → Developer → Fill with sample data).
    @MainActor
    private static func makeStores(settings: AppSettings) -> (TaskStore, DayStreakStore) {
        #if DEBUG
        let launch = UserDefaults.standard
        if launch.bool(forKey: "sampleMode") {
            return (TaskStore(), DayStreakStore(defaults: nil, initial: SampleData.dayStreak))
        }
        #endif
        let container: ModelContainer
        do {
            container = try ModelContainer.habitData()
        } catch {
            fatalError("Couldn't open the saved data: \(error)")
        }
        let repository = HabitRepository(container: container)
        let clock = AppClock()
        #if DEBUG
        if launch.bool(forKey: "resetData") {
            repository.deleteAll()
            clock.resetToRealTime()
            settings.askedForReminders = false
        }
        if let text = launch.string(forKey: "pretendNow") {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            if let date = formatter.date(from: text) { clock.pretend(date) }
        }
        if launch.bool(forKey: "fillSampleData") {
            repository.fillSampleData(now: clock.now())
        }
        #endif
        let store = TaskStore(repository: repository, clock: clock)
        store.reminders = ReminderScheduler(settings: settings)
        return (store, DayStreakStore(defaults: nil, initial: DayStreakState()))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(store)
                .environment(store.clock)
                .environment(dayStreak)
                .environment(appDelegate.router)
                // The app is always dark (design.md §1.1).
                .preferredColorScheme(.dark)
        }
    }
}

/// Owns the tab router and handles reminder notifications: shown even while the app is open, and a tap opens
/// the Today tab.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    let router = AppRouter()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        SoundPlayer.shared.preload()
        NavigationBarStyle.apply()
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await MainActor.run { router.openedFromNotification() }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}

/// The tab bar. In DEBUG builds, `-galleryEntry <id>` on launch shows that Design Gallery entry
/// as the whole screen instead (used to screenshot every state), and the pretend-time banner is set up.
struct RootView: View {
    #if DEBUG
    @Environment(TaskStore.self) private var store
    #endif

    var body: some View {
        #if DEBUG
        if let id = UserDefaults.standard.string(forKey: "galleryEntry") {
            GalleryEntryRoot(id: id)
        } else {
            MainTabView()
                .onAppear { if !store.isSample { PretendTimeBannerWindow.install(clock: store.clock) } }
        }
        #else
        MainTabView()
        #endif
    }
}
