import Foundation
import Observation

/// The day streak the flame follows (context.md §10). Shared by every screen through the environment, next to
/// `TaskStore`.
/// - With saved data, `TaskStore.refresh()` hands it the state calculated from the saved records (`set`).
/// - With sample data (the Design Gallery, `-sampleMode` UI tests) it works the day streak out itself from
///   the sample tasks (`update`), optionally kept in UserDefaults.
@Observable
final class DayStreakStore {
    private(set) var state: DayStreakState {
        didSet { save() }
    }

    /// Nil: nothing is saved (the Design Gallery and tests).
    @ObservationIgnored private let defaults: UserDefaults?
    static let key = "dayStreak.state"

    /// Loads the saved day streak, or starts from `initial` when nothing is saved yet.
    init(defaults: UserDefaults? = .standard, initial: DayStreakState = SampleData.dayStreak) {
        self.defaults = defaults
        if let data = defaults?.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode(DayStreakState.self, from: data) {
            state = saved
        } else {
            state = initial
        }
    }

    /// The state worked out from saved data.
    func set(_ newState: DayStreakState) {
        if newState != state { state = newState }
    }

    /// Sample data: brings the day streak up to date with today's tasks. Call whenever the tasks or the clock change.
    @discardableResult
    func update(tasks: [TaskSnapshot], now: Date) -> [DayStreakRules.Event] {
        let (updated, events) = DayStreakRules.apply(DayRecord(tasks: tasks, now: now), at: now, to: state)
        if updated != state { state = updated }
        return events
    }

    /// What would happen to the day streak with these tasks, without changing anything. The celebration
    /// uses it to know whether a check-in completes the day.
    func preview(tasks: [TaskSnapshot], now: Date) -> DayStreakChange? {
        let (_, events) = DayStreakRules.apply(DayRecord(tasks: tasks, now: now), at: now, to: state)
        return events.lazy.compactMap { if case .grew(let change) = $0 { change } else { nil } }.first
    }

    /// The flame's mood and speech bubble right now.
    func status(tasks: [TaskSnapshot], now: Date) -> FlameStatus {
        FlameStatus(state: state, record: DayRecord(tasks: tasks, now: now), now: now)
    }

    /// The "streak ended" screen was closed: don't show it again for this break.
    func markEndedScreenShown() {
        state.lastBreak?.screenShown = true
    }

    /// Delete all data: back to no day streak at all.
    func reset() {
        state = DayStreakState()
    }

    private func save() {
        guard let defaults, let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
