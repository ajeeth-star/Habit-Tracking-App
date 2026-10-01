import Testing
import UIKit
@testable import HabitApp

/// Checks on the design system and sample data that don't fit the formatter tests.
struct HabitAppTests {
    @Test("Every color has a color set in the asset catalog", arguments: AppColors.assetNames)
    func colorExists(name: String) {
        #expect(UIColor(named: name) != nil)
    }

    @Test func cardStatesCoverEveryHomeState() {
        let states = SampleData.allTasks.map(\.cardState)
        #expect(states.contains(.open))
        #expect(states.contains(.upcoming))
        #expect(states.contains(.skipped))
        #expect(states.contains(.missed))
        #expect(states.contains { if case .done = $0 { true } else { false } })
        #expect(states.contains { if case .notToday = $0 { true } else { false } })
    }

    @Test func skipPromptUsesDaysLeftThisWeek() {
        // Gym: Mon, Tue, Thu, Fri; today is Thursday, so Friday is the only day after today.
        #expect(SampleData.gym.skipPrompt.daysAfterToday == [.friday])
        #expect(SampleData.gym.skipPrompt.isLastSkip)
    }
}
