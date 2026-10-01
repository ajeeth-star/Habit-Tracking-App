import SwiftUI

/// The app's text styles (design.md §1.2). All are built on Dynamic Type text
/// styles, so they grow with the iPhone's text-size setting. Use as `Font.app.cardTitle`.
struct AppFonts {
    let screenTitle = Font.title.bold()
    let successTitle = Font.title2.bold()
    let emptyTitle = Font.title3.weight(.semibold)
    let statValue = Font.title3.weight(.semibold).monospacedDigit()
    let cardTitle = Font.headline
    let button = Font.body.weight(.semibold)
    let body = Font.body
    let subhead = Font.subheadline
    let meta = Font.footnote
    let sectionHeader = Font.footnote.weight(.semibold)
    let pill = Font.caption.weight(.semibold)
    let caption = Font.caption

    /// The 32pt `plus` in the empty-state circle and the `checkmark` on the success screen.
    /// Scales with Dynamic Type, relative to `.largeTitle` (34pt at the default size).
    let largeIcon = Font.system(.largeTitle, weight: .semibold)
}

extension Font {
    static let app = AppFonts()
}
