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
}
