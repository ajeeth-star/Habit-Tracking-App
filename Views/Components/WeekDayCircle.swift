import SwiftUI

/// One scheduled day in "This week": a 32pt circle showing how it went, with the day name below.
struct WeekDayCircle: View {
    let day: Weekday
    let status: WeekDayStatus
    /// The streak's color: done days fill with it. Without one, done days use `success`.
    var color: StreakColor?

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            circle
                .frame(width: Sizes.weekDayCircle, height: Sizes.weekDayCircle)
            Text(Formatters.current.weekdayShortName(day))
                .font(Font.app.caption)
                .foregroundStyle(Color.app.textSecondary)
        }
        // Up to seven sit in one row, so cap the size before the day names collide.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Accessibility.weekDay(Formatters.current.weekdayName(day), statusName))
    }

    @ViewBuilder private var circle: some View {
        switch status {
        case .done:
            if let color {
                Circle().fill(color.main)
                    .overlay { mark("checkmark", Color.app.textOnBright) }
            } else {
                Circle().fill(Color.app.successSoft)
                    .overlay { mark("checkmark", Color.app.success) }
            }
        case .skipped:
            Circle().fill(Color.app.surfaceMuted)
                .overlay { mark("minus", Color.app.textSecondary) }
        case .missed:
            Circle().fill(Color.app.dangerSoft)
                .overlay { mark("xmark", Color.app.danger) }
        case .today:
            Circle().strokeBorder(Color.app.flame, lineWidth: Sizes.weekStripRing)
                .overlay {
                    Circle().fill(Color.app.flame)
                        .frame(width: Sizes.todayDot, height: Sizes.todayDot)
                }
        case .upcoming:
            Circle().fill(Color.app.surfaceMuted)
        }
    }

    private func mark(_ symbol: String, _ color: Color) -> some View {
        Image(systemName: symbol)
            .font(Font.app.pill)
            .foregroundStyle(color)
            // The circle has a fixed size, so the mark stops growing past this text size.
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }

    private var statusName: String {
        switch status {
        case .done: Strings.Accessibility.done
        case .skipped: Strings.Accessibility.skipped
        case .missed: Strings.Accessibility.missed
        case .today: Strings.Accessibility.today
        case .upcoming: Strings.Accessibility.upcoming
        }
    }
}
