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
    static let buttonHeight: CGFloat = 52
    /// Minimum tap target for icon-only buttons.
    static let tapTarget: CGFloat = 44
    /// Card, field, chip, and tab bar borders.
    static let borderWidth: CGFloat = 2
    /// Rings: the "today" ring on the task screen, the selected tab's square.
    static let emphasisStroke: CGFloat = 2

    /// Chunky 3D depth: a button's lip and how far it moves when pressed, and the same for cards.
    static let buttonLip: CGFloat = 4
    static let cardLip: CGFloat = 5
    static let cardPress: CGFloat = 3

    /// Progress bars: height and the glossy stripe along the top of the fill.
    static let progressBar: CGFloat = 16
    static let progressHighlight: CGFloat = 4

    /// The selected tab's rounded square.
    static let tabSelection: CGFloat = 40

    static let pillHorizontalPadding: CGFloat = 8
    static let pillVerticalPadding: CGFloat = 3

    static let weekDayCircle: CGFloat = 32
    static let todayDot: CGFloat = 6
    static let dayChip: CGFloat = 36

    static let emptyStateCircle: CGFloat = 88
    static let emptyStateTextMaxWidth: CGFloat = 260

    /// A streak's icon badge.
    static let iconBadge: CGFloat = 40

    /// Settings: row height, the icon badge on each row, and the thin line between rows.
    static let settingsRow: CGFloat = 52
    static let settingsBadge: CGFloat = 28
    static let rowDivider: CGFloat = 1

    /// Streak style picker: color swatches, the ring around the selected one, and icon cells.
    static let colorSwatch: CGFloat = 32
    static let swatchRing: CGFloat = 2
    static let swatchRingGap: CGFloat = 2
    static let iconCell: CGFloat = 44

    /// Week strip: day circles and their progress rings.
    static let weekStripCircle: CGFloat = 36
    static let weekStripRing: CGFloat = 3

    /// Tab bar height, plus the bottom safe area.
    static let tabBarHeight: CGFloat = 64

    /// The radial glow behind the celebration flame.
    static let celebrationGlow: CGFloat = 280

    /// Photo thumbnail on a History tab row.
    static let historyThumbnail: CGFloat = 56

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
