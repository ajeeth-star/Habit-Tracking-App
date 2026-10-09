import SwiftUI

/// A streak's icon on a soft square of its color (design.md §2). Decorative: the name beside it
/// says what it is, so VoiceOver skips it.
struct IconBadge: View {
    let icon: String
    let color: StreakColor
    /// The hero card style: white at 25% behind a dark navy icon.
    var onHero = false

    var body: some View {
        Image(systemName: icon)
            .font(Font.app.badgeIcon)
            .foregroundStyle(onHero ? Color.app.textOnBright : color.main)
            // The badge has a fixed size, so the icon stops growing past this text size.
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .frame(width: Sizes.iconBadge, height: Sizes.iconBadge)
            .background(onHero ? Color.app.heroBadge : color.badge, in: .rounded(Radius.md))
            .accessibilityHidden(true)
    }
}

extension IconBadge {
    init(task: TaskSnapshot, onHero: Bool = false) {
        self.init(icon: task.icon, color: task.color, onHero: onHero)
    }
}
