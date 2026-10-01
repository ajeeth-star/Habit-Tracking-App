import SwiftUI

/// The card at the top of Home: a progress ring, "2 of 3 done today", and what's next.
struct TodaySummaryCard: View {
    let summary: TodaySummary

    private let format = Formatters.current

    var body: some View {
        HStack(spacing: Spacing.md) {
            ProgressRing(done: summary.done, total: summary.total)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(format.summaryTitle(summary))
                    .font(Font.app.cardTitle)
                    .foregroundStyle(Color.app.textPrimary)
                if let next = summary.nextUp {
                    Text(format.nextUp(next))
                        .font(Font.app.meta)
                        .foregroundStyle(Color.app.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.md)
        .background(Color.app.surface, in: .rounded(Radius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .strokeBorder(Color.app.separator, lineWidth: Sizes.hairline)
        }
        .accessibilityElement(children: .combine)
    }
}
