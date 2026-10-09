import SwiftUI

/// One Settings group (design.md §4.13): header, a chunky card holding the rows, and an optional footer.
/// Put a `SettingsDivider()` between rows.
struct SettingsSection<Rows: View>: View {
    let title: String
    var footer: String?
    @ViewBuilder let rows: Rows

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(Font.app.sectionHeader)
                .foregroundStyle(Color.app.textTertiary)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.xs)
                .padding(.horizontal, Spacing.xxs)
            VStack(spacing: 0) {
                rows
            }
            .clipShape(.rounded(Radius.lg))
            .chunkyCard()
            if let footer {
                Text(footer)
                    .font(Font.app.meta)
                    .foregroundStyle(Color.app.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Spacing.xs)
                    .padding(.horizontal, Spacing.xxs)
            }
        }
    }
}

/// The thin line between two Settings rows, starting after the icon badge.
struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.app.border)
            .frame(height: Sizes.rowDivider)
            .padding(.leading, Spacing.md + Sizes.settingsBadge + Spacing.sm)
    }
}

/// A Settings row: a 28pt colored icon badge, the title, and whatever goes on the right.
struct SettingsRow<Trailing: View>: View {
    let icon: String
    let color: Color
    let title: String
    var titleColor = Color.app.textPrimary
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(spacing: Spacing.sm) {
            SettingsIcon(icon: icon, color: color)
            Text(title)
                .font(Font.app.body)
                .foregroundStyle(titleColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .padding(.horizontal, Spacing.md)
        .frame(minHeight: Sizes.settingsRow)
        .contentShape(Rectangle())
    }
}

extension SettingsRow where Trailing == EmptyView {
    init(icon: String, color: Color, title: String, titleColor: Color = Color.app.textPrimary) {
        self.init(icon: icon, color: color, title: title, titleColor: titleColor) { EmptyView() }
    }
}

/// The 28pt rounded square on the left of a Settings row: a bright fill with a dark navy icon.
struct SettingsIcon: View {
    let icon: String
    let color: Color

    var body: some View {
        Image(systemName: icon)
            .font(Font.app.settingsIcon)
            .foregroundStyle(Color.app.textOnBright)
            .frame(width: Sizes.settingsBadge, height: Sizes.settingsBadge)
            .background(color, in: .rounded(Radius.sm))
            .accessibilityHidden(true)
    }
}
