import SwiftUI

/// The app's text styles (design.md §1.2). Built on Dynamic Type text styles, so they grow with the
/// iPhone's text-size setting. SF Pro Rounded for titles and numbers; regular SF Pro for everything else.
/// Use as `Font.app.cardTitle`.
struct AppFonts {
    // Rounded: titles and numbers
    let screenTitle = Font.system(.title, design: .rounded, weight: .bold)
    let successTitle = Font.system(.title2, design: .rounded, weight: .bold)
    let emptyTitle = Font.system(.title3, design: .rounded, weight: .semibold)
    let statValue = Font.system(.title3, design: .rounded, weight: .semibold).monospacedDigit()
    let cardTitle = Font.system(.headline, design: .rounded, weight: .semibold)
    let cardStreak = Font.system(.headline, design: .rounded, weight: .semibold).monospacedDigit()
    let ringCount = Font.system(.subheadline, design: .rounded, weight: .semibold).monospacedDigit()
    /// Fixed size: decorative and already very large.
    let celebrationNumber = Font.system(size: 64, weight: .bold, design: .rounded).monospacedDigit()
    /// Fixed size: the big flame on the celebration.
    let celebrationIcon = Font.system(size: 96)
    /// Date numbers in the week strip.
    let weekStripNumber = Font.system(.subheadline, design: .rounded, weight: .semibold).monospacedDigit()
    /// Fixed size: side tab icons.
    let tabIcon = Font.system(size: 22)
    /// Fixed size: the sun on the center Today button.
    let centerTabIcon = Font.system(size: 26, weight: .semibold)

    // Regular SF Pro: buttons, body, and supporting text
    let button = Font.body.weight(.semibold)
    let body = Font.body
    let subhead = Font.subheadline
    let meta = Font.footnote
    let sectionHeader = Font.footnote.weight(.semibold)
    let pill = Font.caption.weight(.semibold)
    let caption = Font.caption
    /// The icon inside an `IconBadge`.
    let badgeIcon = Font.body.weight(.semibold)

    /// The 32pt `plus` in the empty-state circle.
    /// Scales with Dynamic Type, relative to `.largeTitle` (34pt at the default size).
    let largeIcon = Font.system(.largeTitle, weight: .semibold)
}

extension Font {
    static let app = AppFonts()
}
