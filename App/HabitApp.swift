import SwiftUI
import UserNotifications

@main
struct HabitApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var settings = AppSettings()
    @State private var store = TaskStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(store)
                .environment(appDelegate.router)
                .preferredColorScheme(settings.appearance.colorScheme)
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
