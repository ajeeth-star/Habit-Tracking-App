import Foundation
import SwiftData

// Saved-data versions (context.md §11). Every layout that has ever been saved on a phone stays here, frozen, so
// SwiftData can recognize old saved data and upgrade it step by step. How to add a version: CLAUDE.md.

/// The layout the app currently saves: the model classes in `Records.swift`.
enum SchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [StreakRecord.self, ScheduleVersionRecord.self, CheckInRecord.self, SkipRecord.self, DayResultRecord.self,
         AppRecord.self, SkippedWindowRecord.self]
    }
}

/// How saved data moves from each version to the next.
enum HabitMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self] }

    /// 1 → 2 only adds things (a new model, new optional fields), so SwiftData does it on its own.
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)]
    }
}

/// Version 1, the "make it real" phase. Frozen: never change these classes.
enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [StreakRecord.self, ScheduleVersionRecord.self, CheckInRecord.self, SkipRecord.self, DayResultRecord.self,
         AppRecord.self]
    }

    @Model
    final class StreakRecord {
        @Attribute(.unique) var id: UUID
        var name: String
        var colorKey: String
        var iconName: String
        var createdAt: Date
        var archivedAt: Date?
        var pastArchivedAt: [Date] = []
        var pastRestoredAt: [Date] = []
        @Relationship(deleteRule: .cascade, inverse: \ScheduleVersionRecord.streak)
        var versions: [ScheduleVersionRecord] = []
        @Relationship(deleteRule: .cascade, inverse: \CheckInRecord.streak)
        var checkIns: [CheckInRecord] = []
        @Relationship(deleteRule: .cascade, inverse: \SkipRecord.streak)
        var skips: [SkipRecord] = []

        init(id: UUID = UUID(), name: String, colorKey: String, iconName: String, createdAt: Date) {
            self.id = id
            self.name = name
            self.colorKey = colorKey
            self.iconName = iconName
            self.createdAt = createdAt
        }
    }

    @Model
    final class ScheduleVersionRecord {
        var id: UUID
        var weekdays: [Int]
        var startMinute: Int
        var endMinute: Int
        var skipsPerWeek: Int
        var effectiveFrom: Date
        var streak: StreakRecord?

        init(id: UUID = UUID(), weekdays: [Int], startMinute: Int, endMinute: Int, skipsPerWeek: Int,
             effectiveFrom: Date) {
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
        var day: Date
        var time: Date
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
        var refunded: Bool
        var streak: StreakRecord?

        init(id: UUID = UUID(), day: Date, time: Date, refunded: Bool = false) {
            self.id = id
            self.day = day
            self.time = time
            self.refunded = refunded
        }
    }

    @Model
    final class DayResultRecord {
        @Attribute(.unique) var day: Date
        var kind: Int
        var missedAt: Date?

        init(day: Date, kind: Int, missedAt: Date?) {
            self.day = day
            self.kind = kind
            self.missedAt = missedAt
        }
    }

    @Model
    final class AppRecord {
        var longestDayStreak: Int = 0
        var bestFlameForm: Int = 0
        var endedScreenShownForBreak: Date?
        var lastProcessedDay: Date?

        init() {}
    }
}
