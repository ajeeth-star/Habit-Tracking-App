import SwiftUI

/// What Home shows before any task exists: a big + and a short invitation.
struct EmptyStateView: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onCreate) {
                Image(systemName: "plus")
                    .font(Font.app.largeIcon)
                    .foregroundStyle(Color.app.onAccent)
                    .frame(width: Sizes.emptyStateCircle, height: Sizes.emptyStateCircle)
                    .background(Color.app.accent, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Strings.Home.createTask)

            Text(Strings.Home.emptyTitle)
                .font(Font.app.emptyTitle)
                .foregroundStyle(Color.app.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.lg)

            Text(Strings.Home.emptyBody)
                .font(Font.app.subhead)
                .foregroundStyle(Color.app.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: Sizes.emptyStateTextMaxWidth)
                .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
    }
}
