import Foundation
import Observation
import SwiftUI

/// The habits every tab shows, kept in memory. For this phase it starts from `SampleData`; the Tasks
/// phase swaps this for saved data. One store is shared by all four tabs, so a check-in, archive, or
/// delete shows up everywhere at once.
@Observable
final class TaskStore {
    var tasks: [TaskSnapshot]

    /// The clock: `startNow` plus however long the app has been open. Sample data fixes "now" for
    /// this phase; the countdown still ticks along from there.
    @ObservationIgnored let startNow: Date
    @ObservationIgnored private let openedAt = Date()

    init(tasks: [TaskSnapshot] = SampleData.allTasksWithArchived, now: Date = SampleData.today) {
        self.tasks = tasks
        self.startNow = now
    }

    func now(at date: Date = Date()) -> Date {
        startNow.addingTimeInterval(max(0, date.timeIntervalSince(openedAt)))
    }

    var today: Weekday { Weekday(startNow) }

    // MARK: Lists

    var active: [TaskSnapshot] { tasks.filter { !$0.isArchived } }
    var archived: [TaskSnapshot] { tasks.filter(\.isArchived) }

    /// Habits tab order: current streak, highest first; ties keep their order.
    var activeByStreak: [TaskSnapshot] {
        active.enumerated()
            .sorted { ($0.element.streak.totalCheckIns, -$0.offset) > ($1.element.streak.totalCheckIns, -$1.offset) }
            .map(\.element)
    }

    /// Every check-in photo kept, archived habits included.
    var photoCount: Int { tasks.reduce(0) { $0 + $1.checkIns.count } }

    func task(_ id: String) -> TaskSnapshot? { tasks.first { $0.id == id } }

    /// A binding to one task, or nil once it's been deleted.
    func binding(for id: String) -> Binding<TaskSnapshot>? {
        guard task(id) != nil else { return nil }
        return Binding {
            self.task(id) ?? SampleData.gym
        } set: { updated in
            self.replace(updated)
        }
    }

    // MARK: Changes

    func replace(_ updated: TaskSnapshot) {
        guard let index = tasks.firstIndex(where: { $0.id == updated.id }) else { return }
        tasks[index] = updated
    }

    func archive(_ id: String) {
        guard let task = task(id) else { return }
        replace(task.archived())
    }

    func restore(_ id: String) {
        guard let task = task(id) else { return }
        replace(task.restored(on: today))
    }

    /// Permanently removes the habit, its streaks, and its photos.
    func delete(_ id: String) {
        tasks.removeAll { $0.id == id }
    }

    /// Permanently removes every habit, streak, and photo. Settings are kept.
    func deleteAll() {
        tasks.removeAll()
    }
}

/// Which tab is showing. Shared so that tapping a reminder notification can switch to Today.
@Observable
final class AppRouter {
    enum Tab: Hashable {
        case history, today, streaks
    }

    var selectedTab = Tab.today

    /// Tapping a reminder notification opens the Today tab.
    func openedFromNotification() {
        selectedTab = .today
    }
}
