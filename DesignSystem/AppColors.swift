import SwiftUI

/// The app's color palette (design.md §1.1). Each name matches a color set in
/// `Resources/Assets.xcassets/Colors/`, which holds its light and dark variants.
/// Use as `Color.app.accent`.
struct AppColors {
    let background = Color("background")
    let surface = Color("surface")
    let surfaceMuted = Color("surfaceMuted")
    let separator = Color("separator")
    let textPrimary = Color("textPrimary")
    let textSecondary = Color("textSecondary")
    let textTertiary = Color("textTertiary")
    let accent = Color("accent")
    let accentText = Color("accentText")
    let accentSoft = Color("accentSoft")
    let onAccent = Color("onAccent")
    let success = Color("success")
    let successSoft = Color("successSoft")
    let danger = Color("danger")
    let dangerSoft = Color("dangerSoft")
    /// The flame icon only. Never used for text.
    let streak = Color("streak")
    /// Dim layer behind the skip dialog.
    let scrim = Color("scrim")

    /// Camera and photo-preview screens are always black with white controls, in both modes.
    let cameraBackground = Color.black
    let cameraForeground = Color.white
    /// "Retake" button fill on the photo preview (white at 15%).
    let cameraButtonFill = Color.white.opacity(0.15)

    /// Every asset-catalog color name, so tests can check each one exists.
    static let assetNames = [
        "background", "surface", "surfaceMuted", "separator",
        "textPrimary", "textSecondary", "textTertiary",
        "accent", "accentText", "accentSoft", "onAccent",
        "success", "successSoft", "danger", "dangerSoft",
        "streak", "scrim",
    ]
}

extension Color {
    static let app = AppColors()
}
