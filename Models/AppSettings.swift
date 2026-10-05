import Observation
import SwiftUI

/// Everything on the Settings tab (design.md §4.13). Saved on the device (UserDefaults) the moment
/// it changes, and read back when the app starts.
@Observable
final class AppSettings {
    enum Appearance: String, CaseIterable {
        case system, light, dark

        /// Nil follows the iPhone's setting.
        var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .light: .light
            case .dark: .dark
            }
        }
    }

    /// Minutes between reminders while a window is open.
    static let repeatChoices = [10, 15, 30]
    /// Minutes before the window closes for the last-call warning.
    static let lastCallChoices = [10, 15, 30]

    var streakDisplay: StreakDisplayMode { didSet { save(streakDisplay.rawValue, Key.streakDisplay) } }
    var appearance: Appearance { didSet { save(appearance.rawValue, Key.appearance) } }
    var repeatMinutes: Int { didSet { save(repeatMinutes, Key.repeatMinutes) } }
    var lastCallMinutes: Int { didSet { save(lastCallMinutes, Key.lastCallMinutes) } }
    /// Off turns off every haptic in the app.
    var vibrations: Bool { didSet { save(vibrations, Key.vibrations) } }
    /// Off shows the celebration without the pop and count-up.
    var celebrationAnimation: Bool { didSet { save(celebrationAnimation, Key.celebrationAnimation) } }
    /// Only used for the greeting on Today. Up to 30 characters, no leading spaces while typing;
    /// `greetingName` trims the rest.
    var name: String {
        didSet {
            let cleaned = Self.clean(name)
            if cleaned != name { name = cleaned; return }
            save(name, Key.name)
        }
    }

    /// The name as the greeting uses it: trimmed, or nil when empty.
    var greetingName: String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static let maxNameLength = 30

    @ObservationIgnored private let defaults: UserDefaults

    private enum Key {
        static let streakDisplay = "settings.streakDisplay"
        static let appearance = "settings.appearance"
        static let repeatMinutes = "settings.repeatMinutes"
        static let lastCallMinutes = "settings.lastCallMinutes"
        static let vibrations = "settings.vibrations"
        static let celebrationAnimation = "settings.celebrationAnimation"
        static let name = "settings.name"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        streakDisplay = defaults.string(forKey: Key.streakDisplay).flatMap(StreakDisplayMode.init) ?? .weeksAndDays
        appearance = defaults.string(forKey: Key.appearance).flatMap(Appearance.init) ?? .system
        repeatMinutes = Self.choice(defaults.integer(forKey: Key.repeatMinutes), in: Self.repeatChoices, default: 15)
        lastCallMinutes = Self.choice(defaults.integer(forKey: Key.lastCallMinutes), in: Self.lastCallChoices, default: 15)
        vibrations = defaults.object(forKey: Key.vibrations) as? Bool ?? true
        celebrationAnimation = defaults.object(forKey: Key.celebrationAnimation) as? Bool ?? true
        name = Self.clean(defaults.string(forKey: Key.name) ?? "")
    }

    /// No leading spaces, at most 30 characters.
    private static func clean(_ name: String) -> String {
        String(name.drop(while: \.isWhitespace).prefix(maxNameLength))
    }

    /// Trims trailing spaces too, e.g. when the name field is left.
    func finishEditingName() {
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// A saved value only counts if it's still one of the choices.
    private static func choice(_ saved: Int, in choices: [Int], default fallback: Int) -> Int {
        choices.contains(saved) ? saved : fallback
    }

    private func save(_ value: Any, _ key: String) {
        defaults.set(value, forKey: key)
    }
}
