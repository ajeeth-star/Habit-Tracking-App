import Foundation
import Observation

/// The one place every rule and screen gets "now" from. In DEBUG builds it can pretend to be a different time
/// (Settings → Developer), saved so it survives restarts; release builds always use the real time.
/// The Design Gallery uses a frozen clock at the sample time.
@Observable
final class AppClock {
    /// Pretend time minus real time. Always 0 in release builds.
    private(set) var offset: TimeInterval
    @ObservationIgnored private let frozen: Date?
    @ObservationIgnored private let defaults: UserDefaults?

    static let offsetKey = "debug.clockOffset"

    init(defaults: UserDefaults? = .standard) {
        frozen = nil
        self.defaults = defaults
        #if DEBUG
        offset = defaults?.double(forKey: Self.offsetKey) ?? 0
        #else
        offset = 0
        #endif
    }

    /// A clock that starts at `date` and ticks on from there, never saved (sample data in UI tests).
    init(startingAt date: Date) {
        frozen = nil
        defaults = nil
        offset = date.timeIntervalSinceNow
    }

    /// A clock that always says `date` (the Design Gallery).
    init(frozenAt date: Date) {
        frozen = date
        defaults = nil
        offset = 0
    }

    /// Now. `real` lets a `TimelineView` pass its own date.
    func now(at real: Date = Date()) -> Date {
        frozen ?? real.addingTimeInterval(offset)
    }

    var isPretending: Bool { offset != 0 }

    #if DEBUG
    func advance(by seconds: TimeInterval) {
        setOffset(offset + seconds)
    }

    /// Pretend it's `date` from now on.
    func pretend(_ date: Date) {
        setOffset(date.timeIntervalSinceNow)
    }

    func resetToRealTime() {
        setOffset(0)
    }

    private func setOffset(_ value: TimeInterval) {
        offset = value
        defaults?.set(value, forKey: Self.offsetKey)
    }
    #endif
}
