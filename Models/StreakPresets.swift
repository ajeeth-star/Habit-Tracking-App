import Foundation

/// A "Popular streaks" chip on the empty state (context.md §5, design.md §4.2): opens the create form filled in.
struct StreakPreset: Identifiable, Hashable {
    var name: String
    var icon: String
    var color: StreakColor
    var days: Set<Weekday>
    var window: TimeWindow

    var id: String { name }

    /// What the create form starts with. Skips start at 0.
    var draft: StreakDraft {
        StreakDraft(name: name, days: days, window: window, skips: 0, color: color, icon: icon)
    }

    static let popular: [StreakPreset] = [
        StreakPreset(name: Strings.Starters.gym, icon: "dumbbell.fill", color: .coral,
                     days: [.monday, .tuesday, .thursday, .friday], window: window(18, 20)),
        StreakPreset(name: Strings.Starters.skincare, icon: "drop.fill", color: .pink,
                     days: Set(Weekday.allCases), window: window(7, 9)),
        StreakPreset(name: Strings.Starters.read, icon: "book.fill", color: .orange,
                     days: Set(Weekday.allCases), window: window(21, 22)),
        StreakPreset(name: Strings.Starters.journal, icon: "pencil", color: .teal,
                     days: Set(Weekday.allCases), window: window(21, 22)),
        StreakPreset(name: Strings.Starters.water, icon: "cup.and.saucer.fill", color: .blue,
                     days: Set(Weekday.allCases), window: window(12, 14)),
        StreakPreset(name: Strings.Starters.walk, icon: "figure.walk", color: .green,
                     days: Set(Weekday.allCases), window: window(17, 19)),
        StreakPreset(name: Strings.Starters.study, icon: "brain.head.profile", color: .purple,
                     days: [.monday, .tuesday, .wednesday, .thursday, .friday], window: window(16, 18)),
        StreakPreset(name: Strings.Starters.cleanUp, icon: "sparkles", color: .yellow,
                     days: [.sunday], window: window(10, 12)),
    ]

    private static func window(_ start: Int, _ end: Int) -> TimeWindow {
        TimeWindow(start: TimeOfDay(start), end: TimeOfDay(end))
    }
}
