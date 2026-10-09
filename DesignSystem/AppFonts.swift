import SwiftUI

/// The app's text styles (design.md §1.2): Nunito everywhere, scaling with the iPhone's text-size
/// setting through `relativeTo:`. Use as `Font.app.cardTitle`.
struct AppFonts {
    // Titles
    let screenTitle = Nunito.extraBold(28, .title)
    let successTitle = Nunito.extraBold(22, .title2)
    let emptyTitle = Nunito.extraBold(20, .title3)
    let cardTitle = Nunito.bold(17, .headline)

    // Big numbers: Black, monospaced digits
    let statValue = Nunito.black(20, .title3).monospacedDigit()
    let cardStreak = Nunito.black(17, .headline).monospacedDigit()
    /// The "2 of 3" count in Today's status line.
    let statusCount = Nunito.black(15, .subheadline).monospacedDigit()
    /// Date numbers in the week strip.
    let weekStripNumber = Nunito.black(15, .subheadline).monospacedDigit()
    /// Fixed size: decorative and already very large.
    let celebrationNumber = Font.custom(Nunito.blackName, fixedSize: 64).monospacedDigit()

    // Labels: shown ALL CAPS with `Typography.capsTracking`
    let button = Nunito.extraBold(15, .subheadline)
    let pill = Nunito.bold(12, .caption)

    // Supporting text: SemiBold
    let body = Nunito.semiBold(17, .body)
    let subhead = Nunito.semiBold(15, .subheadline)
    let meta = Nunito.semiBold(13, .footnote)
    let sectionHeader = Nunito.extraBold(13, .footnote)
    let caption = Nunito.semiBold(12, .caption)

    // SF Symbol sizes (icons only, never text)
    /// Fixed size: the icon inside an `IconBadge` (and icon picker cells, the week strip's done flame).
    let badgeIcon = Font.system(size: 20, weight: .semibold)
    /// Fixed size: the icon inside a Settings row's 28pt badge.
    let settingsIcon = Font.system(size: 15, weight: .semibold)
    /// Fixed size: tab bar icons.
    let tabIcon = Font.system(size: 22, weight: .semibold)
    /// The `plus` in the empty-state circle.
    let largeIcon = Font.system(.largeTitle, weight: .heavy)
    /// Fixed size: the big flame on the celebration.
    let celebrationIcon = Font.system(size: 96)
}

/// The Nunito weights the app uses. One variable font file (`Resources/Fonts/Nunito-Variable.ttf`)
/// provides all of them by name.
enum Nunito {
    static let semiBoldName = "Nunito-SemiBold"
    static let boldName = "Nunito-Bold"
    static let extraBoldName = "Nunito-ExtraBold"
    static let blackName = "Nunito-Black"

    static func semiBold(_ size: CGFloat, _ style: Font.TextStyle) -> Font { .custom(semiBoldName, size: size, relativeTo: style) }
    static func bold(_ size: CGFloat, _ style: Font.TextStyle) -> Font { .custom(boldName, size: size, relativeTo: style) }
    static func extraBold(_ size: CGFloat, _ style: Font.TextStyle) -> Font { .custom(extraBoldName, size: size, relativeTo: style) }
    static func black(_ size: CGFloat, _ style: Font.TextStyle) -> Font { .custom(blackName, size: size, relativeTo: style) }
}

/// Letter spacing for ALL CAPS button labels and status pills.
enum Typography {
    static let capsTracking: CGFloat = 0.8
}

extension View {
    /// ALL CAPS with the button/pill letter spacing. Display only: VoiceOver still reads the original text.
    func capsLabel() -> some View {
        textCase(.uppercase).tracking(Typography.capsTracking)
    }
}

extension Font {
    static let app = AppFonts()
}
