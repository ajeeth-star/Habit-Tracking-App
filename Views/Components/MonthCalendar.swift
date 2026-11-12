import SwiftUI

/// The Progress tab's month calendar (design.md §4.19): weekday letters, then a Monday-first grid of rounded
/// squares, one per day, showing how it went. Past days from the first streak on are tappable.
struct MonthCalendar: View {
    let month: ProgressMonth
    var onOpenDay: (ProgressDay) -> Void = { _ in }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: Spacing.xs) {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Weekday.allCases) { day in
                    Text(Formatters.current.weekdayLetter(day))
                        .font(Font.app.caption)
                        .foregroundStyle(Color.app.textTertiary)
                        .accessibilityHidden(true)
                }
            }
            LazyVGrid(columns: columns, spacing: Spacing.xs) {
                ForEach(0..<month.leadingBlanks, id: \.self) { _ in
                    Color.clear.frame(height: Sizes.calendarDay)
                }
                ForEach(month.days) { day in
                    CalendarDayCell(day: day) { onOpenDay(day) }
                }
            }
        }
    }
}

private struct CalendarDayCell: View {
    let day: ProgressDay
    let onOpen: () -> Void

    private let shape = RoundedRectangle(cornerRadius: Radius.md, style: .continuous)

    var body: some View {
        Button(action: onOpen) {
            face
                .frame(width: Sizes.calendarDay, height: Sizes.calendarDay)
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .disabled(!day.opensHistory)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Formatters.current.progressDayLabel(day))
        .accessibilityAddTraits(day.opensHistory ? .isButton : [])
        .accessibilityIdentifier("progress.day.\(Formatters.current.dayNumber(day.date))")
    }

    @ViewBuilder private var face: some View {
        let number = Text(Formatters.current.dayNumber(day.date)).font(Font.app.weekStripNumber)
        ZStack {
            switch day.kind {
            case .full:
                shape.fill(Color.app.flame)
                // White on flame, like the week strip's done days (design.md §1.1).
                Image(systemName: "flame.fill")
                    .font(Font.app.badgeIcon)
                    .foregroundStyle(Color.app.whiteButton)
            case .partial:
                shape.fill(Color.app.surfaceMuted)
                shape.inset(by: Sizes.calendarRing / 2)
                    .stroke(Color.app.track, lineWidth: Sizes.calendarRing)
                shape.inset(by: Sizes.calendarRing / 2)
                    .trim(from: 0, to: day.progress)
                    .stroke(Color.app.flame, style: StrokeStyle(lineWidth: Sizes.calendarRing, lineCap: .round))
                number.foregroundStyle(day.isToday ? Color.app.flame : Color.app.textPrimary)
            case .missed:
                shape.fill(Color.app.dangerSoft)
                number.foregroundStyle(Color.app.danger)
            case .rest:
                shape.fill(Color.app.surfaceMuted)
                number.foregroundStyle(day.isToday ? Color.app.flame : Color.app.textTertiary)
            case .future:
                number.foregroundStyle(Color.app.textTertiary)
            }
            if day.isToday {
                shape.strokeBorder(Color.app.flame, lineWidth: Sizes.calendarRing)
            }
        }
    }
}
