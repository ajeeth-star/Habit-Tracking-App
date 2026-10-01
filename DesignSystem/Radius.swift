import SwiftUI

/// Corner radii (design.md §1.4). Always used with continuous corners. Use as `Radius.md`.
/// For `full` (pills, chips, circles) use `Capsule()` or `Circle()`.
enum Radius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
}

extension Shape where Self == RoundedRectangle {
    /// A continuous-corner rounded rectangle: `.rounded(Radius.md)`.
    static func rounded(_ radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}
