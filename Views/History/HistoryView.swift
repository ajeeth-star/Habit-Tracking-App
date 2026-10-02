import SwiftUI

/// Every check-in photo for one task, grouped by month, newest first (design.md §4.9).
struct HistoryView: View {
    let task: TaskSnapshot

    @Environment(\.dismiss) private var dismiss
    @State private var openedPhoto: PhotoItem?

    private let format = Formatters.current

    var body: some View {
        Group {
            if task.checkIns.isEmpty {
                Text(Strings.History.empty)
                    .font(Font.app.subhead)
                    .foregroundStyle(Color.app.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                grid
            }
        }
        .background(Color.app.background)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(Font.app.button)
                        .foregroundStyle(Color.app.accentText)
                        .frame(minWidth: Sizes.tapTarget, minHeight: Sizes.tapTarget, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Strings.Detail.back)
            }
            ToolbarItem(placement: .principal) {
                Text(Strings.History.title(task.name))
                    .font(Font.app.cardTitle)
                    .foregroundStyle(Color.app.textPrimary)
                    .lineLimit(1)
            }
        }
        .fullScreenCover(item: $openedPhoto) { photo in
            PhotoViewer(date: photo.date) { openedPhoto = nil }
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(months, id: \.first) { photos in
                    Text(format.monthHeader(photos[0]))
                        .font(Font.app.sectionHeader)
                        .foregroundStyle(Color.app.textTertiary)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, Spacing.xl)
                        .padding(.bottom, Spacing.xs)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 3),
                              alignment: .leading, spacing: Spacing.xs) {
                        ForEach(photos, id: \.self) { date in
                            Button { openedPhoto = PhotoItem(date: date) } label: {
                                VStack(alignment: .leading, spacing: Spacing.xxs) {
                                    PhotoThumbnail()
                                    Text(format.photoDate(date))
                                        .font(Font.app.caption)
                                        .monospacedDigit()
                                        .foregroundStyle(Color.app.textTertiary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
    }

    /// Check-ins split into calendar months, newest month first.
    private var months: [[Date]] {
        let calendar = Calendar.current
        var groups: [[Date]] = []
        for date in task.checkIns.sorted(by: >) {
            if let last = groups.last?.first, calendar.isDate(last, equalTo: date, toGranularity: .month) {
                groups[groups.count - 1].append(date)
            } else {
                groups.append([date])
            }
        }
        return groups
    }

    private struct PhotoItem: Identifiable {
        let date: Date
        var id: Date { date }
    }
}

