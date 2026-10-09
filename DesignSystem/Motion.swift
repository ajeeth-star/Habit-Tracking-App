import SwiftUI

/// Animation timing (design.md §1.6). Every use checks Reduce Motion first.
enum Motion {
    /// Standard quick transitions (~0.25s).
    static let standard = Animation.easeInOut(duration: 0.25)
    /// The celebration flame popping in.
    static let pop = Animation.spring(duration: 0.45, bounce: 0.45)
    /// The streak number counting up, the ring filling, and a hero card closing into a done card.
    static let settle = Animation.spring(duration: 0.6, bounce: 0.2)
    /// How long the streak celebration stays before closing on its own.
    static let celebrationDuration: Duration = .seconds(2.5)
    /// The flame starts at this scale and springs to full size.
    static let popStartScale: CGFloat = 0.5
    /// How long a chunky button or card takes to press down.
    static let press = Animation.easeOut(duration: 0.08)
    /// Cards sliding up as a screen first appears: how far, and the gap between each card.
    static let slideInDistance: CGFloat = 12
    static let slideInStagger: Double = 0.04
    static let slideInMaxStaggered = 10
    static let slideIn = Animation.spring(duration: 0.45, bounce: 0.25)
    /// Confetti: how many pieces and how long they fall.
    static let confettiCount = 50
    static let confettiDuration: Double = 1.5

    // The flame character (design.md §2b)
    /// One breath, 98% → 102% → 98%.
    static let flameBreathPeriod: Double = 2
    static let flameBreathAmount: Double = 0.02
    /// Blinks come every 3–6 seconds and take this long.
    static let flameBlinkInterval: ClosedRange<Double> = 3...6
    static let flameBlinkDuration: Double = 0.14
    /// The sleepy "z": how long one float takes.
    static let flameSleepCycle: Double = 3
    /// Celebration steps: step 1 moves on after this when more steps follow.
    static let celebrationAdvance: Duration = .seconds(2)
    /// The white flash when the flame reaches a new form.
    static let evolutionFlash: Double = 0.2
    /// The flame hopping when the day streak lands.
    static let hopHeight: CGFloat = 28
}
