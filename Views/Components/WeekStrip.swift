import SwiftUI

/// Monday to Sunday of this week on the Today tab (design.md §4.1): each past day's circle shows how
/// much of it got done, today shows its progress so far. Tapping a past day calls `onSelectPastDay`
/// (Today opens History at that day); today and future days aren't tappable.
struct WeekStrip: View {
    let days: [WeekStripDay]
    var onSelectPastDay: (WeekStripDay) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days) { day in
                column(day)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("weekStrip.\(day.weekday.rawValue)")
            }
        }
        // Seven fixed-size circles sit in one row, so the text stops growing before they collide.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    @ViewBuilder private func column(_ day: WeekStripDay) -> some View {
        let content = VStack(spacing: Spacing.xxs) {
            Text(Formatters.current.weekdayLetter(day.weekday))
                .font(Font.app.caption)
                .foregroundStyle(Color.app.textTertiary)
            DayCircle(day: day)
        }
        let label = Formatters.current.weekStripLabel(day)
        if day.isPast {
            Button { onSelectPastDay(day) } label: {
                content
                    .frame(maxWidth: .infinity, minHeight: Sizes.tapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(label)
        } else {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
        }
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
