import Foundation

/// What the create/edit form fills in (design.md §4.3).
struct StreakDraft: Equatable {
    var name = ""
    var days: Set<Weekday> = []
    var window = TimeWindow(start: TimeOfDay(7), end: TimeOfDay(9))
    var skips = 0
    var color = StreakColor.coral
    var icon = StreakIcon.fallback
}

/// The window-only check-in rule (context.md §4), in one clearly named place so it can be loosened later:
/// a check-in counts only while today's window is open.
enum CheckInRule {
    static func isAllowed(opens: Date, closes: Date, now: Date) -> Bool {
        opens <= now && now < closes
    }
}
