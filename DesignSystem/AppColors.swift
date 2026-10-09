import SwiftUI

/// The app's palette (design.md §1.1). The app is always dark, so each color is a single value.
/// Names match the color sets in `Resources/Assets.xcassets/Colors/`. Use as `Color.app.flame`.
struct AppColors {
    // Neutrals
    let background = Color("background")
    let surface = Color("surface")
    let surfaceRaised = Color("surfaceRaised")
    let surfaceMuted = Color("surfaceMuted")
    let border = Color("border")
    let textPrimary = Color("textPrimary")
    let textSecondary = Color("textSecondary")
    let textTertiary = Color("textTertiary")
    /// Small text and icons on any bright fill.
    let textOnBright = Color("textOnBright")

    // Bright colors, each with a darker lip for the 3D edge
    /// The brand color.
    let flame = Color("flame")
    let flameLip = Color("flameLip")
    let success = Color("success")
    let successLip = Color("successLip")
    let danger = Color("danger")
    let dangerLip = Color("dangerLip")
    let info = Color("info")
    let infoLip = Color("infoLip")
    let gold = Color("gold")
    let goldLip = Color("goldLip")
    let purple = Color("purple")
    let purpleLip = Color("purpleLip")

    // Fixed extras
    let disabled = Color("disabled")
    let disabledLip = Color("disabledLip")
    /// The empty part of progress bars and rings.
    let track = Color("track")
    /// The hero card's Check in button.
    let whiteButton = Color("whiteButton")
    let whiteButtonLip = Color("whiteButtonLip")
    /// Dim layer behind dialogs.
    let scrim = Color("scrim")

    // Tints, derived (design.md §1.1)
    let flameSoft = Color("flame").opacity(0.2)
    let successSoft = Color("success").opacity(0.2)
    let dangerSoft = Color("danger").opacity(0.2)
    let infoSoft = Color("info").opacity(0.15)
    /// Secondary text on a hero card.
    let onBrightMuted = Color("textOnBright").opacity(0.75)
    /// The icon badge background on a hero card: white at 25%, so it stands out on the streak color.
    let heroBadge = Color.white.opacity(0.25)
    /// The glossy stripe along the top of a progress bar fill.
    let highlight = Color.white.opacity(0.3)

    /// Camera, photo preview, and photo viewer stay black with white controls.
    let cameraBackground = Color.black
    let cameraForeground = Color.white
    /// "Retake" on the photo preview, on black.
    let cameraButtonFill = Color.white.opacity(0.15)

    /// The bright colors confetti is drawn in.
    var confetti: [Color] { [flame, success, danger, info, gold, purple] }

    /// Every asset-catalog color name, so tests can check each one exists.
    static let assetNames = [
        "background", "surface", "surfaceRaised", "surfaceMuted", "border",
        "textPrimary", "textSecondary", "textTertiary", "textOnBright",
        "flame", "flameLip", "success", "successLip", "danger", "dangerLip",
        "info", "infoLip", "gold", "goldLip", "purple", "purpleLip",
        "disabled", "disabledLip", "track", "whiteButton", "whiteButtonLip", "scrim",
    ] + StreakColor.allCases.flatMap { [$0.assetName, $0.assetName + "Lip"] }
}

extension Color {
    static let app = AppColors()
}
