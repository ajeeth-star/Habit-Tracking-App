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
}
