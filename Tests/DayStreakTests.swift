import Foundation
import Testing
@testable import HabitApp

/// The day streak rules (context.md §10), the flame's forms, moods, and speech bubble, and saving.
@MainActor
struct DayStreakTests {
    private let calendar = Calendar.current
    /// Thursday, October 1, 2026 (midnight).
    private let day = Calendar.current.startOfDay(for: SampleData.today)

    private func at(_ hour: Int, _ minute: Int = 0, dayOffset: Int = 0) -> Date {
        let base = calendar.date(byAdding: .day, value: dayOffset, to: day)!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base)!
    }

    private func item(_ id: String, _ opens: Int, _ closes: Int, _ outcome: DayStreakItem.Outcome = .pending,
                      dayOffset: Int = 0) -> DayStreakItem {
        DayStreakItem(taskID: id, taskName: id.capitalized, opens: at(opens, dayOffset: dayOffset),
                      closes: at(closes, dayOffset: dayOffset), outcome: outcome)
    }

    private func record(_ items: [DayStreakItem], dayOffset: Int = 0) -> DayRecord {
        DayRecord(day: calendar.date(byAdding: .day, value: dayOffset, to: day)!, items: items)
    }

    private func apply(_ record: DayRecord, at now: Date, to state: DayStreakState) -> (DayStreakState, [DayStreakRules.Event]) {
        DayStreakRules.apply(record, at: now, to: state)
    }

    private let five = DayStreakState(current: 5, longest: 10, bestForm: .flame)

    // MARK: Counting

    @Test func normalDayAddsOneWhenTheLastItemIsResolved() {
        let halfway = record([item("gym", 18, 20, .checkedIn(at: at(18, 30))), item("journal", 21, 22)])
        let (before, noEvents) = apply(halfway, at: at(19), to: five)
        #expect(before.current == 5)
        #expect(noEvents.isEmpty)

        let done = record([item("gym", 18, 20, .checkedIn(at: at(18, 30))), item("journal", 21, 22, .checkedIn(at: at(21, 5)))])
        let (after, events) = apply(done, at: at(21, 5), to: before)
        #expect(after.current == 6)
        #expect(events == [.grew(DayStreakChange(from: 5, to: 6, isRevival: false))])
    }

    @Test func aDayOnlyCountsOnce() {
        let done = record([item("gym", 18, 20, .checkedIn(at: at(18, 30)))])
        let (once, _) = apply(done, at: at(18, 30), to: five)
        let (twice, events) = apply(done, at: at(23), to: once)
        #expect(twice.current == 6)
        #expect(events.isEmpty)
    }

    @Test func restDayKeepsItWithoutAdding() {
        let (state, events) = apply(record([]), at: at(23), to: five)
        #expect(state == five)
        #expect(events.isEmpty)
    }

    @Test func allSkipDayKeepsItWithoutAdding() {
        let skipped = record([item("gym", 18, 20, .skipped), item("run", 7, 9, .skipped)])
        let (state, events) = apply(skipped, at: at(23), to: five)
        #expect(state.current == 5)
        #expect(state.lastBreak == nil)
        #expect(events.isEmpty)
    }

    @Test func skipsPlusOneCheckInAdds() {
        let mixed = record([item("gym", 18, 20, .skipped), item("run", 7, 9, .checkedIn(at: at(7, 30)))])
        #expect(apply(mixed, at: at(23), to: five).0.current == 6)
    }

    @Test func severalStreaksOnOneDayNeedAllOfThem() {
        let items = [item("a", 7, 9, .checkedIn(at: at(8))), item("b", 12, 13, .skipped),
                     item("c", 17, 19, .checkedIn(at: at(18))), item("d", 21, 22)]
        #expect(apply(record(items), at: at(20), to: five).0.current == 5)
        var all = items
        all[3].outcome = .checkedIn(at: at(21, 30))
        #expect(apply(record(all), at: at(21, 30), to: five).0.current == 6)
    }

    // MARK: Ending

    @Test func aMissMidDayEndsItTheMomentTheWindowCloses() {
        let items = [item("guitar", 12, 13), item("gym", 18, 20)]
        let (beforeClose, _) = apply(record(items), at: at(12, 59), to: five)
        #expect(beforeClose.current == 5)

        let (ended, events) = apply(record(items), at: at(13), to: five)
        #expect(ended.current == 0)
        #expect(ended.longest == 10)
        #expect(ended.lastBreak == .init(day: day, at: at(13), length: 5))
        #expect(events == [.ended(length: 5)])
        #expect(ended.needsEndedScreen)

        // Checking in everything else later that day doesn't bring it back today.
        let later = [item("guitar", 12, 13), item("gym", 18, 20, .checkedIn(at: at(18, 10)))]
        let (stillZero, laterEvents) = apply(record(later), at: at(18, 10), to: ended)
        #expect(stillZero.current == 0)
        #expect(laterEvents.isEmpty)
    }

    @Test func aBreakIsRecordedOnce() {
        let missed = record([item("guitar", 12, 13)])
        let (ended, _) = apply(missed, at: at(13), to: five)
        let (again, events) = apply(missed, at: at(20), to: ended)
        #expect(again == ended)
        #expect(events.isEmpty)
    }

    @Test func aMissWithNoStreakEndsNothing() {
        let (state, events) = apply(record([item("guitar", 12, 13)]), at: at(14), to: DayStreakState())
        #expect(state.lastBreak == nil)
        #expect(!state.needsEndedScreen)
        #expect(events.isEmpty)
    }

    @Test func breakThenRevival() {
        let (ended, _) = apply(record([item("guitar", 12, 13)]), at: at(14), to: five)
        let tomorrow = record([item("gym", 18, 20, .checkedIn(at: at(18, 5, dayOffset: 1)), dayOffset: 1)], dayOffset: 1)
        let (back, events) = apply(tomorrow, at: at(18, 5, dayOffset: 1), to: ended)
        #expect(back.current == 1)
        #expect(back.longest == 10)
        #expect(back.bestForm == .flame)
        #expect(events == [.grew(DayStreakChange(from: 0, to: 1, isRevival: true))])
        #expect(DayStreakChange(from: 0, to: 1, isRevival: true).newForm == nil)
    }

    @Test func severalDaysInOrder() {
        let records = [
            record([item("gym", 18, 20, .checkedIn(at: at(18, 5, dayOffset: 1)), dayOffset: 1)], dayOffset: 1),
            record([], dayOffset: 2),
            record([item("gym", 18, 20, dayOffset: 3)], dayOffset: 3),
        ]
        let (state, events) = DayStreakRules.apply(records, at: at(9, dayOffset: 4), to: five)
        #expect(events == [.grew(DayStreakChange(from: 5, to: 6, isRevival: false)), .ended(length: 6)])
        #expect(state.current == 0)
        #expect(state.longest == 10)
    }

    @Test func longestAndBestFormGrow() {
        let state = DayStreakState(current: 13, longest: 13, bestForm: .flame)
        let (after, events) = apply(record([item("gym", 18, 20, .checkedIn(at: at(18)))]), at: at(18), to: state)
        #expect(after.longest == 14)
        #expect(after.bestForm == .blaze)
        #expect(events == [.grew(DayStreakChange(from: 13, to: 14, isRevival: false))])
        #expect(DayStreakChange(from: 13, to: 14, isRevival: false).newForm == .blaze)
        #expect(DayStreakChange(from: 14, to: 15, isRevival: false).newForm == nil)
    }

    // MARK: Building today's record from streaks

    @Test func streakCreatedMidDayOnlyCountsFromItsFirstWindowAfterCreation() {
        var lateWindow = SampleData.journal // 9–10 PM, not done yet
        lateWindow.createdAt = at(15)
        var earlyWindow = SampleData.gym // 6–8 PM
        earlyWindow.createdAt = at(19)
        let today = DayRecord(tasks: [lateWindow, earlyWindow], now: at(19, 30))
        #expect(today.items.map(\.taskID) == [lateWindow.id])

        // Gym's window closing unchecked doesn't end anything: it doesn't count today.
        let (state, _) = DayStreakRules.apply(DayRecord(tasks: [earlyWindow], now: at(20, 30)), at: at(20, 30), to: five)
        #expect(state.current == 5)
    }

    @Test func archivingStopsCountingButDoesntChangeThePast() {
        let open = SampleData.gym
        let done = SampleData.skincare
        // Before archiving: Gym still open, so the day isn't complete.
        let (before, _) = DayStreakRules.apply(DayRecord(tasks: [done, open], now: at(18, 40)), at: at(18, 40), to: five)
        #expect(before.current == 5)
        // Archived: it leaves today's record, so the day is complete.
        let (after, _) = DayStreakRules.apply(DayRecord(tasks: [done, open.archived()], now: at(18, 41)),
                                              at: at(18, 41), to: before)
        #expect(after.current == 6)

        // A break that already happened stays, even if the missed streak is archived afterwards.
        let (ended, _) = DayStreakRules.apply(DayRecord(tasks: [SampleData.guitar], now: at(13, 30)), at: at(13, 30), to: five)
        let (stillEnded, _) = DayStreakRules.apply(DayRecord(tasks: [SampleData.guitar.archived()], now: at(14)),
                                                   at: at(14), to: ended)
        #expect(stillEnded.current == 0)
        #expect(stillEnded.lastBreak?.length == 5)
    }

    @Test func sampleDataEndsTheTwentyThreeDayStreak() {
        let (state, events) = DayStreakRules.apply(DayRecord(tasks: SampleData.allTasksWithArchived, now: SampleData.today),
                                                   at: SampleData.today, to: SampleData.dayStreak)
        #expect(events == [.ended(length: 23)])
        #expect(state.longest == 30)
        #expect(state.bestForm == .bonfire)
        // Healthy sample: Journal is still to come, so nothing changes yet.
        let healthy = DayStreakRules.apply(DayRecord(tasks: SampleData.healthyTasks, now: SampleData.today),
                                           at: SampleData.today, to: SampleData.dayStreak).0
        #expect(healthy.current == 23)
    }

    // MARK: Forms

    @Test func formsByDays() {
        let expected: [(Int, FlameForm)] = [(0, .ember), (1, .spark), (6, .spark), (7, .flame), (13, .flame),
                                             (14, .blaze), (29, .blaze), (30, .bonfire), (49, .bonfire),
                                             (50, .inferno), (99, .inferno), (100, .wildfire), (364, .wildfire),
                                             (365, .eternal), (1000, .eternal)]
        for (days, form) in expected { #expect(FlameForm(days: days) == form, "\(days) days") }
    }

    @Test func daysToNextForm() {
        let format = Formatters(locale: Locale(identifier: "en_US"))
        #expect(format.toNextForm(days: 23) == "7 days to Bonfire")
        #expect(format.toNextForm(days: 6) == "1 day to Flame")
        #expect(format.toNextForm(days: 0) == "1 day to Spark")
        #expect(format.toNextForm(days: 400) == "You've reached the final form.")
        #expect(FlameForm.progress(days: 22) == 0.5)
        #expect(FlameForm.progress(days: 400) == 1)
    }

    // MARK: Mood and speech bubble

    @Test func moodsInPriorityOrder() {
        let state = five
        // Sad beats worried: ended today, and an open window is about to close.
        let ended = DayStreakState(current: 0, longest: 10, lastBreak: .init(day: day, at: at(13), length: 5))
        let closing = record([item("guitar", 12, 13), item("gym", 18, 20)])
        #expect(FlameStatus(state: ended, record: closing, now: at(19, 50)).mood == .sad)
        #expect(FlameStatus(state: ended, record: closing, now: at(19, 50)).bubble == .streakEnded)

        // A check-in after the break cheers it up.
        let checkedInSince = record([item("guitar", 12, 13), item("gym", 18, 20, .checkedIn(at: at(18, 30))),
                                     item("journal", 21, 22)])
        #expect(FlameStatus(state: ended, record: checkedInSince, now: at(18, 40)).mood == .happy)

        let worried = FlameStatus(state: state, record: record([item("gym", 18, 20)]), now: at(19, 48))
        #expect(worried.mood == .worried)
        #expect(worried.bubble == .closingSoon(task: "Gym", minutes: 12))

        let open = FlameStatus(state: state, record: record([item("gym", 18, 20)]), now: at(18, 40))
        #expect(open.mood == .happy)
        #expect(open.bubble == .open(task: "Gym"))

        let upcoming = FlameStatus(state: state, record: record([item("journal", 21, 22)]), now: at(18, 40))
        #expect(upcoming.bubble == .upcoming(task: "Journal", start: at(21)))

        let proud = FlameStatus(state: state, record: record([item("gym", 18, 20, .skipped)]), now: at(18, 40))
        #expect(proud.mood == .proud)
        #expect(proud.bubble == .allDone)

        let rest = FlameStatus(state: state, record: record([]), now: at(18, 40))
        #expect(rest.mood == .sleepy)
        #expect(rest.bubble == .restDay)

        let dayOver = FlameStatus(state: ended, record: checkedInSince.withJournalSkipped, now: at(18, 40))
        #expect(dayOver.bubble == .dayOver)
    }

    @Test func bubbleLines() {
        let format = Formatters(locale: Locale(identifier: "en_US"))
        #expect(format.bubble(.open(task: "Gym"), variant: 0) == "Gym is open — let's do this!")
        #expect(format.bubble(.open(task: "Gym"), variant: 1) == "Time for gym. I'm ready when you are.")
        #expect(format.bubble(.closingSoon(task: "Gym", minutes: 12)) == "Gym closes in 12 min! Quick, snap a photo!")
        // Apple's formatter puts a narrow no-break space before "PM"; compare it as a normal space.
        #expect(format.bubble(.upcoming(task: "Journal", start: at(21))).replacingOccurrences(of: "\u{202F}", with: " ")
            == "Next up: Journal at 9:00 PM.")
        #expect(format.bubble(.allDone, variant: 1) == "That's everything. Proud of you.")
        #expect(format.bubble(.restDay) == "Rest day. Recharging for tomorrow.")
        #expect(format.bubble(.streakEnded) == "That's okay. One check-in brings me back.")
        #expect(format.flameAccessibility(form: .blaze, mood: .happy, days: 23)
            == "Your flame. Blaze form. Happy. 23 day streak.")
        #expect(format.dayStreakStats(longest: 30, bestForm: .bonfire) == "Longest: 30 days · Best form: Bonfire")
        #expect(Strings.DayStreakEnded.title(23) == "Your 23-day streak ended")
    }

    // MARK: Celebration steps

    @Test func celebrationSteps() {
        #expect(StreakCelebrationView.steps(for: nil) == [.checkIn])
        #expect(StreakCelebrationView.steps(for: DayStreakChange(from: 22, to: 23, isRevival: false)) == [.checkIn, .dayStreak])
        #expect(StreakCelebrationView.steps(for: DayStreakChange(from: 0, to: 1, isRevival: true)) == [.checkIn, .dayStreak])
        #expect(StreakCelebrationView.steps(for: DayStreakChange(from: 29, to: 30, isRevival: false))
            == [.checkIn, .dayStreak, .newForm(from: .blaze, to: .bonfire)])
    }

    // MARK: Saving

    @Test func savesAndShowsTheEndedScreenOnce() {
        let suite = "test.dayStreak.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = DayStreakStore(defaults: defaults, initial: SampleData.dayStreak)
        store.update(tasks: SampleData.allTasksWithArchived, now: SampleData.today)
        #expect(store.state.needsEndedScreen)
        store.markEndedScreenShown()

        let reopened = DayStreakStore(defaults: defaults, initial: DayStreakState())
        #expect(reopened.state.current == 0)
        #expect(reopened.state.longest == 30)
        #expect(reopened.state.bestForm == .bonfire)
        #expect(!reopened.state.needsEndedScreen)

        reopened.reset()
        #expect(DayStreakStore(defaults: defaults).state == DayStreakState())
    }

    @Test func previewDoesntChangeAnything() {
        let store = DayStreakStore(defaults: nil, initial: SampleData.dayStreak)
        store.update(tasks: SampleData.lastOneLeftTasks, now: SampleData.today)
        let gymDone = SampleData.lastOneLeftTasks.map { $0.id == SampleData.gym.id ? $0.checkedIn(at: SampleData.today) : $0 }
        #expect(store.preview(tasks: gymDone, now: SampleData.today) == DayStreakChange(from: 23, to: 24, isRevival: false))
        #expect(store.state.current == 23)
    }
}

private extension DayRecord {
    /// The same day with Journal skipped.
    var withJournalSkipped: DayRecord {
        var copy = self
        copy.items = items.map { var item = $0; if item.taskID == "journal" { item.outcome = .skipped }; return item }
        return copy
    }
}
