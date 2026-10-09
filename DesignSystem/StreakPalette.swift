import SwiftUI

/// The 8 bright streak colors (design.md §1.1b), each with a darker lip. Each streak has one.
/// Use as `StreakColor.coral.main`.
enum StreakColor: String, CaseIterable, Hashable, Identifiable {
    case coral, orange, yellow, green, teal, blue, purple, pink

    var id: Self { self }

    /// The color itself (`streakCoral` in the asset catalog).
    var main: Color { Color(assetName) }

    /// The darker 3D edge under a chunky fill (`streakCoralLip`).
    var lip: Color { Color(assetName + "Lip") }

    /// `main` at 20%: icon badge backgrounds and selected icon cells.
    var badge: Color { main.opacity(0.2) }

    /// "streakCoral"
    var assetName: String { "streak" + rawValue.prefix(1).uppercased() + rawValue.dropFirst() }

    /// What VoiceOver calls it: "Coral".
    var accessibilityName: String { Strings.StreakStyle.colorName(self) }

    /// A new streak gets the first color not used by `used`; all taken starts again at coral.
    static func nextUnused(after used: [StreakColor]) -> StreakColor {
        allCases.first { !used.contains($0) } ?? .coral
    }
}

/// The icons a streak can have (design.md §1.1b), all SF Symbols available on iOS 17.
enum StreakIcon {
    static let all = [
        "dumbbell.fill", "figure.run", "figure.walk", "bicycle", "drop.fill", "sparkles",
        "book.fill", "pencil", "brain.head.profile", "guitars.fill", "music.note", "paintbrush.fill",
        "fork.knife", "cup.and.saucer.fill", "leaf.fill", "bed.double.fill", "moon.fill", "sun.max.fill",
        "heart.fill", "cross.case.fill", "house.fill", "cart.fill", "laptopcomputer", "star.fill",
    ]

    static let fallback = "star.fill"

    /// Words in a streak's name that suggest an icon, checked in order.
    private static let guesses: [(words: [String], icon: String)] = [
        (["gym", "lift"], "dumbbell.fill"),
        (["run"], "figure.run"),
        (["skin", "face"], "drop.fill"),
        (["read"], "book.fill"),
        (["guitar"], "guitars.fill"),
        (["dishes", "clean"], "sparkles"),
        (["sleep"], "bed.double.fill"),
    ]

    /// An icon guessed from the name: "Gym" → dumbbell, "Morning skincare" → drop, otherwise a star.
    static func guess(for name: String) -> String {
        let lowered = name.lowercased()
        return guesses.first { $0.words.contains { lowered.contains($0) } }?.icon ?? fallback
    }
}

