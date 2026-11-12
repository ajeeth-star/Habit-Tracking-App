import Foundation
import SwiftData
import Testing
import UIKit
@testable import HabitApp

/// The Progress tab's numbers (context.md §5), the "Popular streaks" presets, and the flame cheering the first
/// streak on.
@MainActor
struct ProgressTests {
    private let calendar = Calendar.current

    /// November 2026, local time. November 2 is a Monday.
    private func day(_ day: Int, month: Int = 11) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day))!
    }

    private func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    /// A streak whose days went as given.
    private func task(_ id: String, _ marks: [Date: DayMark], created: Date, archived: Bool = false) -> TaskSnapshot {
        var task = TaskSnapshot(
            id: id, name: id, days: Weekday.allCases, window: TimeWindow(start: TimeOfDay(18), end: TimeOfDay(20)),
            skipsPerWeek: 1, skipsLeft: 1, streak: .zero, longest: .zero, today: .scheduled(.before, .none),
            week: [], checkIns: [], isArchived: archived, createdAt: created)
        task.recordedDays = marks
        return task
    }

    // MARK: Calendar days

    @Test func classifiesEachDay() {
        let gym = task("gym", [
            day(2): .done, day(3): .done, day(4): .missed, day(5): .skipped, day(10): .done, day(11): .pending,
        ], created: day(2))
        let read = task("read", [day(2): .done, day(3): .skipped, day(4): .done, day(5): .skipped, day(10): .pending],
                        created: day(2))
        let stats = ProgressStats(tasks: [gym, read], now: at(11, 12))
        let month = stats.month(offset: 0)
        func kind(_ n: Int) -> ProgressDay.Kind { month.days[n - 1].kind }

        #expect(month.start == day(1))
        #expect(month.leadingBlanks == 6) // November 1, 2026 is a Sunday
        #expect(month.days.count == 30)
        #expect(kind(1) == .rest)      // before the first streak
        #expect(kind(2) == .full)
        #expect(kind(3) == .full)      // a check-in and a skip
        #expect(kind(4) == .missed)
        #expect(kind(5) == .partial)   // everything skipped
        #expect(kind(6) == .rest)
        #expect(kind(10) == .partial)  // (the "today" in the data is the 11th; read's window was still pending)
        #expect(month.days[10].isToday)
        #expect(kind(11) == .partial)  // today, still to do
        #expect(kind(12) == .future)
        #expect(month.days[1].opensHistory)
        #expect(!month.days[0].opensHistory) // before the first streak
        #expect(!month.days[10].opensHistory) // today
        #expect(month.days[9].done == 1 && month.days[9].total == 2)
    }

    @Test func monthStatsCountOnlyUpToToday() {
        // 2 full, 3 full, 4 full, 5 missed, 6 rest, 7 full, 8 all skipped, 9 full, 10 full, 11 today (to do).
        var marks: [Date: DayMark] = [:]
        for n in [2, 3, 4, 7, 9, 10] { marks[day(n)] = .done }
        marks[day(5)] = .missed
        marks[day(8)] = .skipped
        marks[day(11)] = .pending
        let stats = ProgressStats(tasks: [task("gym", marks, created: day(2))], now: at(11, 12))
        let month = stats.month(offset: 0).stats
        #expect(month.checkIns == 6)
        #expect(month.perfectDays == 6)
        // 6 check-ins out of 8 resolved windows (the skip counts against; today's doesn't count yet).
        #expect(month.completionRate == 6.0 / 8.0)
        // 2-3-4, then a miss; 7, rest (keeps it), all-skipped (keeps it), 9, 10 → 3 in a row.
        #expect(month.longestDayStreak == 3)
    }

    @Test func monthWithNothingToCountHasNoRate() {
        let stats = ProgressStats(tasks: [task("new", [day(11): .pending], created: at(11, 9))], now: at(11, 12))
        let month = stats.month(offset: 0).stats
        #expect(month.completionRate == nil)
        #expect(month.checkIns == 0)
        #expect(Formatters.current.rate(month.completionRate) == "—")
    }

    // MARK: Month switching

    @Test func monthsRunFromTheFirstStreakToNow() {
        let stats = ProgressStats(tasks: [task("gym", [day(20, month: 9): .done], created: day(20, month: 9))],
                                  now: at(11, 12))
        #expect(stats.monthRange == day(1, month: 9)...day(1))
        #expect(stats.month(offset: -1).start == day(1, month: 10))
        #expect(stats.month(offset: -2).start == day(1, month: 9))
        // Past the limits it stays at the first or the current month.
        #expect(stats.month(offset: -5).start == day(1, month: 9))
        #expect(stats.month(offset: 3).start == day(1))
    }

    // MARK: Streak rows and best day

    @Test func recentRatesCoverTheLast30DaysOfActiveStreaks() {
        var gymMarks: [Date: DayMark] = [day(11, month: 10): .missed] // 31 days back: left out
        for n in 1...10 { gymMarks[day(n)] = n <= 6 ? .done : .skipped }
        let gym = task("gym", gymMarks, created: day(1, month: 10))
        let old = task("old", [day(3): .done], created: day(1), archived: true)
        let rates = ProgressStats(tasks: [gym, old], now: at(10, 21)).recentRates(order: [gym, old])
        #expect(rates.count == 1)
        #expect(rates[0].task.id == "gym")
        #expect(rates[0].rate == 0.6)
    }

    @Test func bestDayNeedsTwoWeeksAndPicksTheHighestRate() {
        // Mondays 2 and 9 done; Tuesdays 3 done, 10 missed; the rest skipped.
        var marks: [Date: DayMark] = [:]
        for n in 2...15 { marks[day(n)] = .skipped }
        marks[day(2)] = .done
        marks[day(9)] = .done
        marks[day(3)] = .done
        marks[day(10)] = .missed
        let gym = task("gym", marks, created: day(2))
        #expect(ProgressStats(tasks: [gym], now: at(15, 12)).bestDay == nil) // 13 days old
        let best = ProgressStats(tasks: [gym], now: at(16, 12)).bestDay
        #expect(best == BestDay(weekday: .monday, rate: 1))
        #expect(Formatters(locale: Locale(identifier: "en_US")).bestDay(best!) == "Mondays are your strongest day (100%)")
    }

    // MARK: Real saved data

    @Test func savedDataMarksEveryDay() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ProgressTests-\(UUID().uuidString)")
        let repository = HabitRepository(container: try ModelContainer.habitData(inMemory: true),
                                         photos: PhotoStore(folder: folder))
        let id = repository.create(StreakDraft(name: "Gym", days: Set(Weekday.allCases),
                                               window: TimeWindow(start: TimeOfDay(18), end: TimeOfDay(20)),
                                               skips: 1, color: .coral, icon: "dumbbell.fill"), now: at(2, 9))
        try repository.checkIn(id, photo: UIImage(systemName: "star")!, now: at(2, 18, 30))
        #expect(repository.skip(id, now: at(3, 10)))
        repository.catchUp(now: at(5, 12))
        let snapshot = repository.rules.snapshot(repository.record(id)!.data, now: at(5, 12))
        #expect(snapshot.recordedDays == [day(2): .done, day(3): .skipped, day(4): .missed, day(5): .pending])
    }

    // MARK: Presets and the first streak

    @Test func presetsFillInTheCreateForm() {
        #expect(StreakPreset.popular.count == 8)
        #expect(Set(StreakPreset.popular.map(\.color)).count == 8)
        for preset in StreakPreset.popular {
            #expect(StreakIcon.all.contains(preset.icon))
            #expect(preset.window.isValid)
            #expect(preset.draft.skips == 0)
        }
        let gym = StreakPreset.popular[0].draft
        #expect(gym.name == "Gym")
        #expect(gym.days == [.monday, .tuesday, .thursday, .friday])
        #expect(gym.window == TimeWindow(start: TimeOfDay(18), end: TimeOfDay(20)))
    }

    @Test func flameCheersTheFirstStreakUntilItsFirstCheckIn() {
        let store = DayStreakStore(defaults: nil, initial: DayStreakState())
        let now = SampleData.time(10, 0)
        let fresh = SampleData.reading
        let first = store.status(tasks: [fresh], now: now)
        #expect(first.mood == .cheering)
        #expect(first.bubble == .firstStreak)
        #expect(Formatters.current.bubble(first.bubble) == Strings.Bubble.firstStreak)
        // Once anything has ever been checked in, it's back to the usual lines.
        #expect(store.status(tasks: [fresh, SampleData.journal], now: now).bubble != .firstStreak)
        // With no streaks at all, there's nothing to cheer.
        #expect(store.status(tasks: [], now: now).bubble != .firstStreak)
    }
}
