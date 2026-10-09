import Foundation
import SwiftData

// What's saved on the iPhone (context.md §11), with SwiftData. Everything screens show is calculated
// from these by `StreakRules`; `HabitRepository` reads and writes them.

/// One streak (habit). Its schedule, check-ins, and skips are deleted with it.
@Model
final class StreakRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    /// A `StreakColor` raw value.
    var colorKey: String
    /// An SF Symbol name.
    var iconName: String
    var createdAt: Date
    /// Set while archived.
    var archivedAt: Date?
    /// Earlier archive periods, kept so past days can still be judged: `pastArchivedAt[i]` was restored at
    /// `pastRestoredAt[i]`.
    var pastArchivedAt: [Date] = []
    var pastRestoredAt: [Date] = []

    @Relationship(deleteRule: .cascade, inverse: \ScheduleVersionRecord.streak)
    var versions: [ScheduleVersionRecord] = []
    @Relationship(deleteRule: .cascade, inverse: \CheckInRecord.streak)
    var checkIns: [CheckInRecord] = []
    @Relationship(deleteRule: .cascade, inverse: \SkipRecord.streak)
    var skips: [SkipRecord] = []
    /// Version 2: windows a clock change jumped over.
    @Relationship(deleteRule: .cascade, inverse: \SkippedWindowRecord.streak)
    var skippedWindows: [SkippedWindowRecord] = []

    init(id: UUID = UUID(), name: String, colorKey: String, iconName: String, createdAt: Date) {
        self.id = id
        self.name = name
        self.colorKey = colorKey
        self.iconName = iconName
        self.createdAt = createdAt
    }
}

/// The days, window, and skips a streak uses from `effectiveFrom` (midnight, local time) on.
@Model
final class ScheduleVersionRecord {
    var id: UUID
    /// `Weekday` raw values (Monday = 1).
    var weekdays: [Int]
    /// Minutes after midnight, local time.
    var startMinute: Int
    var endMinute: Int
    var skipsPerWeek: Int
    var effectiveFrom: Date
    var streak: StreakRecord?

    init(id: UUID = UUID(), weekdays: [Int], startMinute: Int, endMinute: Int, skipsPerWeek: Int, effectiveFrom: Date) {
        self.id = id
        self.weekdays = weekdays
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.skipsPerWeek = skipsPerWeek
        self.effectiveFrom = effectiveFrom
    }
}

@Model
final class CheckInRecord {
    @Attribute(.unique) var id: UUID
    /// Midnight at the start of the day it counts for.
    var day: Date
    var time: Date
    /// The JPEG in the app's private Photos folder.
    var photoFileName: String
    var streak: StreakRecord?

    init(id: UUID = UUID(), day: Date, time: Date, photoFileName: String) {
        self.id = id
        self.day = day
        self.time = time
        self.photoFileName = photoFileName
    }
}

@Model
final class SkipRecord {
    @Attribute(.unique) var id: UUID
    var day: Date
    var time: Date
    /// A later check-in that day gave it back.
    var refunded: Bool
    var streak: StreakRecord?

    init(id: UUID = UUID(), day: Date, time: Date, refunded: Bool = false) {
        self.id = id
        self.day = day
        self.time = time
        self.refunded = refunded
    }
}

/// One fully processed day's result for the day streak. Saved so deleting a streak never rewrites past days.
@Model
final class DayResultRecord {
    @Attribute(.unique) var day: Date
    /// A `DayResultKind` raw value.
    var kind: Int
    /// When the first window closed unresolved (broken days only).
    var missedAt: Date?

    init(day: Date, kind: DayResultKind, missedAt: Date?) {
        self.day = day
        self.kind = kind.rawValue
        self.missedAt = missedAt
    }
}

/// The app's own records (one row).
@Model
final class AppRecord {
    var longestDayStreak: Int = 0
    /// A `FlameForm` raw value.
    var bestFlameForm: Int = 0
    /// The day of the break the "streak ended" screen was last shown for.
    var endedScreenShownForBreak: Date?
    /// The last day whose result is saved.
    var lastProcessedDay: Date?
    /// When the app last looked at the clock, and the time zone's offset from GMT then (seconds), so a time zone
    /// change can be noticed (version 2).
    var lastSeenAt: Date?
    var lastSeenOffset: Int?

    init() {}
}

/// A window a time zone or daylight-saving change jumped over entirely: not a miss, like an unscheduled day
/// (version 2; context.md §11).
@Model
final class SkippedWindowRecord {
    /// Midnight at the start of the day.
    var day: Date
    var streak: StreakRecord?

    init(day: Date) {
        self.day = day
    }
}

extension ModelContainer {
    /// The current saved-data layout.
    static let schema = Schema(versionedSchema: SchemaV2.self)

    /// The app's saved data, upgraded from any older version first, or an in-memory one (tests).
    static func habitData(inMemory: Bool = false, url: URL? = nil) throws -> ModelContainer {
        let configuration = if let url {
            ModelConfiguration(schema: schema, url: url)
        } else {
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        }
        return try ModelContainer(for: schema, migrationPlan: HabitMigrationPlan.self, configurations: configuration)
    }
}

extension Calendar {
    /// The calendar day a saved "day" belongs to, in this calendar's time zone. Days are saved as the moment of
    /// local midnight; after a time zone change that moment can fall on the evening before, so it's read as noon
    /// of the same date instead (right for time zone changes of under 12 hours; context.md §11).
    func savedDay(_ stored: Date) -> Date {
        startOfDay(for: stored.addingTimeInterval(12 * 3600))
    }
}

extension StreakRecord {
    /// The record as plain values for `StreakRules`, with saved days read in `calendar`'s time zone.
    func data(calendar: Calendar = .autoupdatingCurrent) -> StreakData {
        var archives = zip(pastArchivedAt, pastRestoredAt).map { ArchivePeriod(archivedAt: $0, restoredAt: $1) }
        if let archivedAt { archives.append(ArchivePeriod(archivedAt: archivedAt, restoredAt: nil)) }
        return StreakData(
            id: id,
            name: name,
            color: StreakColor(rawValue: colorKey) ?? .orange,
            icon: iconName,
            createdAt: createdAt,
            archives: archives.sorted { $0.archivedAt < $1.archivedAt },
            versions: versions.map { $0.data(calendar: calendar) },
            checkIns: checkIns.map {
                CheckInData(id: $0.id, day: calendar.savedDay($0.day), time: $0.time, photoFileName: $0.photoFileName)
            },
            skips: skips.map {
                SkipData(id: $0.id, day: calendar.savedDay($0.day), time: $0.time, refunded: $0.refunded)
            },
            skippedDays: Set(skippedWindows.map { calendar.savedDay($0.day) }))
    }

    /// The record as plain values, in the phone's current time zone.
    var data: StreakData { data() }
}

extension ScheduleVersionRecord {
    func data(calendar: Calendar = .autoupdatingCurrent) -> ScheduleData {
        ScheduleData(
            weekdays: Set(weekdays.compactMap(Weekday.init(rawValue:))),
            window: TimeWindow(start: TimeOfDay(startMinute / 60, startMinute % 60),
                               end: TimeOfDay(endMinute / 60, endMinute % 60)),
            skipsPerWeek: skipsPerWeek,
            effectiveFrom: calendar.savedDay(effectiveFrom))
    }
}
