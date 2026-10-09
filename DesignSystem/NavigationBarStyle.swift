import UIKit

/// The system navigation bar (History's title, the "< Today" back button, Settings' "Done") in the app's
/// look: navy background, Nunito text that still scales with the text-size setting, flame-colored buttons.
/// Applied once at launch.
enum NavigationBarStyle {
    static func apply() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "background")
        appearance.shadowColor = .clear
        let white = UIColor(named: "textPrimary") ?? .white
        appearance.titleTextAttributes = [.font: font(Nunito.extraBoldName, 17, .headline), .foregroundColor: white]
        appearance.largeTitleTextAttributes = [.font: font(Nunito.extraBoldName, 34, .largeTitle), .foregroundColor: white]

        let buttons = UIBarButtonItemAppearance()
        buttons.normal.titleTextAttributes = [.font: font(Nunito.boldName, 17, .body)]
        appearance.buttonAppearance = buttons
        appearance.backButtonAppearance = buttons
        appearance.doneButtonAppearance = buttons

        let bar = UINavigationBar.appearance()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
        bar.tintColor = UIColor(named: "flame")
    }

    private static func font(_ name: String, _ size: CGFloat, _ style: UIFont.TextStyle) -> UIFont {
        let base = UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: .bold)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: base)
    }
}
