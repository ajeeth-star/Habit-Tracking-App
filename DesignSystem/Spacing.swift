import CoreGraphics

/// The 4-point spacing grid (design.md §1.3). Use as `Spacing.md`.
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
}

/// Fixed sizes and line widths from the spec (design.md §1.5, §2, §4).
enum Sizes {
    /// Height of every button.
    static let buttonHeight: CGFloat = 50
    /// Minimum tap target for icon-only buttons.
    static let tapTarget: CGFloat = 44
    /// Card outline and other hairlines.
    static let hairline: CGFloat = 0.5
    /// The open-task card outline and the "today" ring.
    static let emphasisStroke: CGFloat = 1.5

    static let pillHorizontalPadding: CGFloat = 8
    static let pillVerticalPadding: CGFloat = 3

    static let weekDayCircle: CGFloat = 32
    static let todayDot: CGFloat = 6
    static let dayChip: CGFloat = 36

    static let emptyStateCircle: CGFloat = 88
    static let emptyStateTextMaxWidth: CGFloat = 260

    /// Photo thumbnail on a History tab row.
    static let historyThumbnail: CGFloat = 56

    /// Progress ring on the today summary card: diameter and line width.
    static let progressRing: CGFloat = 56
    static let progressRingLine: CGFloat = 8

    /// Skip dialog: screen width minus this, capped at `dialogMaxWidth`.
    static let dialogHorizontalInset: CGFloat = 48
    static let dialogMaxWidth: CGFloat = 340

    /// Camera shutter: inner circle, ring width, and the gap between them.
    static let shutterInner: CGFloat = 72
    static let shutterRing: CGFloat = 4
    static let shutterGap: CGFloat = 4

    /// Text field padding on the task form.
    static let fieldPadding: CGFloat = 12
    /// Longest allowed task name.
    static let maxTaskNameLength = 40
}
