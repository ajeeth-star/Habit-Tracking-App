import Foundation
import Observation
import SwiftUI
import UIKit

/// The streaks every tab shows, as snapshots for the screens. Shared by all tabs, so a check-in, archive, or
/// delete shows up everywhere at once.
///
/// Two modes:
/// - **Saved data** (the app): changes go to `HabitRepository`, and `refresh()` recalculates every snapshot from
///   the saved records at the clock's "now".
/// - **Sample data** (the Design Gallery and UI tests that use `-sampleMode`): in-memory `SampleData`, changed in
///   place, never saved.
@Observable
final class TaskStore {
    private(set) var tasks: [TaskSnapshot]
    /// How many photos are saved and how much space they take (Settings → Photo storage). Sample data has no
    /// photo files, so it counts check-ins at an estimated size.
    var photoUsage: (count: Int, bytes: Int64) {
        guard isSample else { return savedPhotoUsage }
        let count = tasks.reduce(0) { $0 + $1.checkIns.count }
        return (count, Int64(count) * SampleData.estimatedPhotoBytes)
    }
    private var savedPhotoUsage: (count: Int, bytes: Int64) = (0, 0)

    @ObservationIgnored let clock: AppClock
    @ObservationIgnored private let repository: HabitRepository?
    /// Kept up to date by `refresh()`.
    @ObservationIgnored var dayStreak: DayStreakStore?
    /// Saved data only: kept in step with the streaks on every `refresh()`.
    @ObservationIgnored var reminders: ReminderScheduler?
    /// Set when the very first streak is created, so Today can offer to turn on reminders (context.md §7).
    var createdFirstStreak = false

    var isSample: Bool { repository == nil }

    /// Sample data. `frozen` stops the clock at `now` (the Design Gallery); otherwise it ticks on from `now`.
    init(tasks: [TaskSnapshot] = SampleData.allTasksWithArchived, now: Date = SampleData.today, frozen: Bool = false) {
        self.tasks = tasks
        repository = nil
        clock = frozen ? AppClock(frozenAt: now) : AppClock(startingAt: now)
    }

    /// Saved data.
    @MainActor
    init(repository: HabitRepository, clock: AppClock) {
        self.repository = repository
        self.clock = clock
        tasks = []
        refresh()
    }

    func now(at date: Date = Date()) -> Date { clock.now(at: date) }

    var today: Weekday { Weekday(now()) }

    /// Catches up on days that passed and recalculates everything from the saved records.
    @MainActor
    func refresh() {
        let now = now()
        guard let repository else {
            dayStreak?.update(tasks: tasks, now: now)
            return
        }
        repository.catchUp(now: now)
        let streaks = repository.streaks()
        let updated = streaks.map { repository.rules.snapshot($0, now: now) }
        if updated != tasks { tasks = updated }
        let usage = repository.photos.usage()
        if usage != savedPhotoUsage { savedPhotoUsage = usage }
        dayStreak?.set(repository.dayStreakState(now: now, streaks: streaks))
        // Reminders follow the real time, never the pretend clock.
        reminders?.reschedule(streaks, rules: repository.rules)
    }

    /// Seconds until something changes on its own: the next window opening or closing today (at most a minute).
    func secondsUntilNextChange() -> Double {
        let now = now()
        let calendar = Calendar.current
        let boundaries = tasks.filter(\.isScheduledToday).flatMap { task in
            [task.window.start, task.window.end].compactMap {
                calendar.date(bySettingHour: $0.hour, minute: $0.minute, second: 0, of: now)
            }
        }
        let next = boundaries.filter { $0 > now }.min().map { $0.timeIntervalSince(now) + 0.5 } ?? 60
        return min(max(next, 1), 60)
    }

    // MARK: Lists

    var active: [TaskSnapshot] { tasks.filter { !$0.isArchived } }
    var archived: [TaskSnapshot] { tasks.filter(\.isArchived) }

    /// Streaks tab order: current streak, highest first; ties keep their order.
    var activeByStreak: [TaskSnapshot] {
        active.enumerated()
            .sorted { ($0.element.streak.totalCheckIns, -$0.offset) > ($1.element.streak.totalCheckIns, -$1.offset) }
            .map(\.element)
    }

    func task(_ id: String) -> TaskSnapshot? { tasks.first { $0.id == id } }

    /// A binding to one task, or nil once it's been deleted. Writing to it only works for sample data.
    func binding(for id: String) -> Binding<TaskSnapshot>? {
        guard let first = task(id) else { return nil }
        return Binding {
            self.task(id) ?? first
        } set: { updated in
            self.replace(updated)
        }
    }

    // MARK: Changes

    /// Sample data only: swaps in a changed snapshot.
    func replace(_ updated: TaskSnapshot) {
        guard isSample, let index = tasks.firstIndex(where: { $0.id == updated.id }) else { return }
        tasks[index] = updated
    }

    @MainActor
    func create(_ draft: StreakDraft) {
        if let repository {
            let isFirst = tasks.isEmpty
            repository.create(draft, now: now())
            refresh()
            if isFirst { createdFirstStreak = true }
        } else {
            tasks.append(Self.sampleSnapshot(draft, today: today))
        }
    }

    @MainActor
    func update(_ id: String, with draft: StreakDraft) {
        if let repository {
            repository.update(id, with: draft, now: now())
            refresh()
        } else if var task = task(id) {
            task.name = draft.name
            task.color = draft.color
            task.icon = draft.icon
            task.window = draft.window
            replace(task)
        }
    }

    @MainActor
    func archive(_ id: String) {
        if let repository {
            repository.archive(id, now: now())
            refresh()
        } else if let task = task(id) {
            replace(task.archived())
        }
    }

    @MainActor
    func restore(_ id: String) {
        if let repository {
            repository.restore(id, now: now())
            refresh()
        } else if let task = task(id) {
            replace(task.restored(on: today))
        }
    }

    /// Permanently removes the streak, its check-ins, and its photos.
    @MainActor
    func delete(_ id: String) {
        if let repository {
            repository.delete(id, now: now())
            refresh()
        } else {
            tasks.removeAll { $0.id == id }
        }
    }

    /// Permanently removes every streak, photo, and record. Settings are kept.
    @MainActor
    func deleteAll() {
        if let repository {
            repository.deleteAll()
            refresh()
        } else {
            tasks.removeAll()
            dayStreak?.reset()
        }
    }

    /// Checks a streak in with its photo. False when today's window isn't open (`CheckInRule`).
    @MainActor
    @discardableResult
    func checkIn(_ id: String, photo: UIImage?, at date: Date) -> Bool {
        if let repository {
            do {
                try repository.checkIn(id, photo: photo ?? Self.placeholderPhoto(), now: date)
            } catch {
                refresh()
                return false
            }
            refresh()
            reminders?.clearDelivered(for: id)
            return true
        }
        guard let task = task(id) else { return false }
        replace(task.checkedIn(at: date))
        dayStreak?.update(tasks: tasks, now: date)
        return true
    }

    /// Uses one of this week's skips for today.
    @MainActor
    func skip(_ id: String) {
        if let repository {
            repository.skip(id, now: now())
            refresh()
            reminders?.clearDelivered(for: id)
        } else if var task = task(id), case .scheduled(let phase, .none) = task.today, task.skipsLeft > 0 {
            task.today = .scheduled(phase, .skipped)
            task.skipsLeft -= 1
            if let index = task.week.lastIndex(where: { $0.status != .upcoming }) { task.week[index].status = .skipped }
            replace(task)
        }
    }

    /// What checking `id` in now would do to the day streak (celebration steps 2 and 3).
    @MainActor
    func previewDayStreak(checkingIn id: String, at date: Date) -> DayStreakChange? {
        if let repository { return repository.previewCheckIn(id, now: date) }
        let checkedIn = tasks.map { $0.id == id ? $0.checkedIn(at: date) : $0 }
        return dayStreak?.preview(tasks: checkedIn, now: date)
    }

    @MainActor
    func markEndedScreenShown() {
        guard let lastBreak = dayStreak?.state.lastBreak else { return }
        repository?.markEndedScreenShown(forBreakOn: lastBreak.day)
        dayStreak?.markEndedScreenShown()
    }

    #if DEBUG
    /// Settings → Developer → Fill with sample data.
    @MainActor
    func fillSampleData() {
        repository?.fillSampleData(now: now())
        refresh()
    }
    #endif

    // MARK: Helpers

    /// A gray stand-in, only used if a check-in somehow arrives without a photo.
    private static func placeholderPhoto() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
    }

    /// A new sample-data streak (Design Gallery only).
    private static func sampleSnapshot(_ draft: StreakDraft, today: Weekday) -> TaskSnapshot {
        let days = draft.days.sorted()
        return TaskSnapshot(
            id: UUID().uuidString, name: draft.name, days: days, window: draft.window, skipsPerWeek: draft.skips,
            skipsLeft: draft.skips, streak: .zero, longest: .zero,
            today: days.contains(today) ? .scheduled(.before, .none) : .notToday(next: .tomorrow),
            week: days.map { WeekDayEntry(day: $0, status: $0 == today ? .today : .upcoming) },
            checkIns: [], color: draft.color, icon: draft.icon)
    }
}

/// Which tab is showing. Shared so that tapping a reminder notification can switch to Today.
@Observable
final class AppRouter {
    enum Tab: Hashable {
        case today, streaks
    }

    var selectedTab = Tab.today

    /// True while a full-page screen (History) is pushed: the tab bar slides away.
    var hidesTabBar = false

    /// Tapping a reminder notification opens the Today tab.
    func openedFromNotification() {
        selectedTab = .today
    }
}
