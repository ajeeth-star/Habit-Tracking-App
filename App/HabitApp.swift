import SwiftUI
import UserNotifications

@main
struct HabitApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var settings = AppSettings()
    @State private var store: TaskStore
    @State private var dayStreak: DayStreakStore

    init() {
        let store = TaskStore()
        #if DEBUG
        // UI tests launch with `-resetDayStreak YES` to start from the sample day streak every time.
        if UserDefaults.standard.bool(forKey: "resetDayStreak") {
            UserDefaults.standard.removeObject(forKey: DayStreakStore.key)
        }
        #endif
        let dayStreak = DayStreakStore()
        // Up to date before the first frame, so the flame and the "streak ended" screen are right at launch.
        dayStreak.update(tasks: store.tasks, now: store.now())
        _store = State(initialValue: store)
        _dayStreak = State(initialValue: dayStreak)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(store)
                .environment(dayStreak)
                .environment(appDelegate.router)
                // The app is always dark (design.md §1.1).
                .preferredColorScheme(.dark)
        }
    }
}

/// Owns the tab router and listens for taps on reminder notifications, which open the Today tab.
/// No reminders are scheduled yet; that's the reminders phase.
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
}

/// The tab bar. In DEBUG builds, `-galleryEntry <id>` on launch shows that Design Gallery entry
/// as the whole screen instead (used to screenshot every state).
struct RootView: View {
    var body: some View {
        #if DEBUG
        if let id = UserDefaults.standard.string(forKey: "galleryEntry") {
            GalleryEntryRoot(id: id)
        } else {
            MainTabView()
        }
        #else
        MainTabView()
        #endif
    }
}
