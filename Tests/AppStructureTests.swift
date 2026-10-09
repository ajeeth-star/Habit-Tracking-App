import Foundation
import Testing
@testable import HabitApp

/// Settings, the shared task store, and the History timeline. Sample "now" is Thursday,
/// October 1, 2026, 6:40 PM.
struct AppStructureTests {
    // MARK: Settings

    /// A throwaway UserDefaults so tests never touch the app's real settings.
    private func freshDefaults() -> UserDefaults {
        let name = "AppStructureTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func settingsDefaults() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.streakDisplay == .weeksAndDays)
        #expect(settings.sounds)
        #expect(settings.repeatMinutes == 15)
        #expect(settings.lastCallMinutes == 15)
        #expect(settings.vibrations)
        #expect(settings.celebrationAnimation)
    }

    @Test func settingsAreRememberedAfterTheAppCloses() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.streakDisplay = .daysOnly
        settings.sounds = false
        settings.repeatMinutes = 30
        settings.lastCallMinutes = 10
        settings.vibrations = false
        settings.celebrationAnimation = false

        let reopened = AppSettings(defaults: defaults)
        #expect(reopened.streakDisplay == .daysOnly)
        #expect(!reopened.sounds)
        #expect(reopened.repeatMinutes == 30)
        #expect(reopened.lastCallMinutes == 10)
        #expect(!reopened.vibrations)
        #expect(!reopened.celebrationAnimation)
    }

    @Test func nameIsOptionalSavedAndTrimmed() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.name.isEmpty)
        #expect(settings.greetingName == nil)

        settings.name = "   Ajeeth"
        #expect(settings.name == "Ajeeth", "Leading spaces are dropped while typing")
        settings.name = "Ajeeth  "
        #expect(settings.greetingName == "Ajeeth")
        settings.finishEditingName()
        #expect(settings.name == "Ajeeth")
        #expect(AppSettings(defaults: defaults).name == "Ajeeth", "Remembered after the app closes")

        settings.name = String(repeating: "a", count: 40)
        #expect(settings.name.count == 30)
    }

    @Test func unknownSavedValuesFallBackToDefaults() {
        let defaults = freshDefaults()
        defaults.set(7, forKey: "settings.repeatMinutes")
        let settings = AppSettings(defaults: defaults)
        #expect(settings.repeatMinutes == 15)
    }

    // MARK: Store

    @Test func habitsSortByCurrentStreak() {
        let store = TaskStore()
        let names = store.activeByStreak.map(\.name)
        #expect(names.first == "Morning skincare") // 32 check-ins
        #expect(names.last == "Long Sunday walk with the dog and a podcast" || names.last == "Guitar") // 0
        #expect(!names.contains("Meditation"))     // archived
        let streaks = store.activeByStreak.map(\.streak.totalCheckIns)
        #expect(streaks == streaks.sorted(by: >))
    }

    @Test func archivingEndsTheStreakButKeepsBestAndPhotos() {
        let store = TaskStore()
        let before = store.task("gym")!
        store.archive("gym")
        let after = store.task("gym")!
        #expect(after.isArchived)
        #expect(after.streak == .zero)
        #expect(after.longest == before.best)
        #expect(after.checkIns == before.checkIns)
        #expect(!store.active.contains { $0.id == "gym" })
        #expect(store.archived.contains { $0.id == "gym" })
    }

    @Test func archivingKeepsAHigherCurrentStreakAsBest() {
        // Skincare's current streak (4w 4d) is also its best; archiving must not lose it.
        let archived = SampleData.skincare.archived()
        #expect(archived.longest.totalCheckIns == 32)
    }

    @Test func restoringStartsFreshFromTheNextScheduledDay() {
        let store = TaskStore()
        store.restore("meditation") // Mon, Wed, Fri; today is Thursday
        let restored = store.task("meditation")!
        #expect(!restored.isArchived)
        #expect(restored.streak == .zero)
        #expect(restored.longest == SampleData.meditation.longest)
        #expect(restored.today == .notToday(next: .tomorrow)) // Friday
        #expect(restored.week.map(\.day) == [.friday])
        #expect(restored.skipsLeft == restored.skipsPerWeek)
    }

    @Test func deletingRemovesTheHabitAndItsPhotos() {
        let store = TaskStore()
        let photos = store.photoCount
        let gymPhotos = store.task("gym")!.checkIns.count
        store.delete("gym")
        #expect(store.task("gym") == nil)
        #expect(store.photoCount == photos - gymPhotos)
        #expect(store.binding(for: "gym") == nil)
    }

    @Test func deletingEverything() {
        let store = TaskStore()
        store.deleteAll()
        #expect(store.tasks.isEmpty)
        #expect(store.photoCount == 0)
    }

    @Test func photoCountIncludesArchivedHabits() {
        let store = TaskStore()
        let expected = SampleData.allTasksWithArchived.reduce(0) { $0 + $1.checkIns.count }
        #expect(store.photoCount == expected)
        #expect(SampleData.meditation.checkIns.count > 0)
    }

    @Test func notificationTapOpensToday() {
        let router = AppRouter()
        router.selectedTab = .streaks
        router.openedFromNotification()
        #expect(router.selectedTab == .today)
    }

    @Test func nextWindowAfterToday() {
        #expect(SampleData.climbing.nextWindow(after: .thursday)?.daysAhead == 1) // Friday
        #expect(SampleData.walk.nextWindow(after: .thursday)?.daysAhead == 3)     // Sunday
        #expect(SampleData.walk.nextWindow(after: .thursday)?.start == TimeOfDay(10))
    }

    // MARK: History

    @Test func historyHasCheckInsSkipsAndMisses() {
        let events = HistoryTimeline.events(for: SampleData.allTasks, now: SampleData.today)
        #expect(events.contains { $0.taskName == "Run" && $0.kind == .skip })
        #expect(events.contains {
            $0.taskName == "Guitar" && $0.kind == .miss(streakEnded: Streak(weeks: 3, days: 3, totalCheckIns: 15))
        })
        #expect(events.filter { $0.kind == .checkIn }.count
            == SampleData.allTasks.reduce(0) { $0 + $1.checkIns.count })
        #expect(events.map(\.date) == events.map(\.date).sorted(by: >))
        // Nothing in the future.
        #expect(events.allSatisfy { $0.date <= SampleData.today.addingTimeInterval(6 * 3600) })
    }

    @Test func historyGroupsByDayNewestFirst() {
        let days = HistoryTimeline.days(for: SampleData.allTasks, now: SampleData.today)
        let calendar = Calendar.current
        #expect(calendar.isDate(days[0].date, inSameDayAs: SampleData.today))
        #expect(days.map(\.date) == days.map(\.date).sorted(by: >))
        #expect(Set(days.map(\.date)).count == days.count)
    }

    @Test func historyFilteredToOneHabit() {
        let days = HistoryTimeline.days(for: [SampleData.guitar], now: SampleData.today)
        #expect(days.allSatisfy { $0.events.allSatisfy { $0.taskID == "guitar" } })
    }
}
