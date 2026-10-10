import BackgroundTasks
import Foundation

/// Background app refresh (context.md §7): when iOS gives the app some time while it isn't open, it processes
/// finished days and redoes the reminder schedule. iOS decides when (and whether) that happens, so it helps keep
/// reminders going but isn't guaranteed; the safety-net reminder covers the rest.
enum BackgroundRefresh {
    /// Also listed in Info.plist (`BGTaskSchedulerPermittedIdentifiers`, via project.yml).
    static let identifier = "com.ajeethsrinivasan.habitapp.refresh"
    /// The earliest the app asks to be woken again. iOS usually waits longer.
    static let interval: TimeInterval = 2 * 3600

    /// Asks iOS for the next background refresh. Called when the app goes to the background and after each run.
    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date().addingTimeInterval(interval)
        try? BGTaskScheduler.shared.submit(request)
    }

    /// One background run: book the next one, then catch up and reschedule reminders, waiting until iOS has them.
    @MainActor
    static func run(_ store: TaskStore) async {
        schedule()
        store.refresh()
        await store.reminders?.finishScheduling()
    }
}
