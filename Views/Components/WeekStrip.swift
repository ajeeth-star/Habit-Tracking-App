import SwiftUI

/// Monday to Sunday of this week on the Today tab (design.md §4.1): each past day's circle shows how
/// much of it got done, today shows its progress so far. Not tappable in this phase.
struct WeekStrip: View {
    let days: [WeekStripDay]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days) { day in
                VStack(spacing: Spacing.xxs) {
                    Text(Formatters.current.weekdayLetter(day.weekday))
                        .font(Font.app.caption)
                        .foregroundStyle(Color.app.textTertiary)
                    DayCircle(day: day)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Formatters.current.weekStripLabel(day))
            }
        }
        // Seven fixed-size circles sit in one row, so the text stops growing before they collide.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }
}

private struct DayCircle: View {
    let day: WeekStripDay
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if day.isComplete {
                Circle().fill(Color.app.accent)
            } else if day.kind == .today {
                Circle()
                    .strokeBorder(Color.app.accent, lineWidth: Sizes.emphasisStroke)
                    .padding(Sizes.weekStripRing)
            }
            if day.kind != .plain && !day.isComplete {
                // The progress ring hugs the outside of the circle.
                Circle()
                    .stroke(Color.app.surfaceMuted, lineWidth: Sizes.weekStripRing)
                    .padding(Sizes.weekStripRing / 2)
                Circle()
                    .trim(from: 0, to: day.progress)
                    .stroke(Color.app.accent, style: StrokeStyle(lineWidth: Sizes.weekStripRing, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(Sizes.weekStripRing / 2)
            }
            Text(Formatters.current.dayNumber(day.date))
                .font(Font.app.weekStripNumber)
                .foregroundStyle(numberColor)
        }
        .frame(width: Sizes.weekStripCircle, height: Sizes.weekStripCircle)
        .animation(reduceMotion ? nil : Motion.settle, value: day.done)
    }

    private var numberColor: Color {
        if day.isComplete { return Color.app.onAccent }
        switch day.kind {
        case .today: return Color.app.accentText
        case .past: return Color.app.textPrimary
        case .plain: return Color.app.textTertiary
        }
    }
}
