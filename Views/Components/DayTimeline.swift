import SwiftUI

/// Today's timeline of the day (design.md §4.1): a line down the left with each streak at its window start, its
/// time on the left, a dot in its status color on the line, and its card on the right. Done and skipped streaks
/// stay in their slot, faded. A flame-colored "now" line sits between the streaks that have started and the ones
/// still to come, and moves as time passes.
struct DayTimeline<Card: View>: View {
    let timeline: TodayTimeline
    let now: Date
    @ViewBuilder let card: (TaskSnapshot) -> Card
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Item: Identifiable {
        case task(TaskSnapshot)
        case now
        var id: String {
            switch self {
            case .task(let task): task.id
            case .now: "now"
            }
        }
    }

    private var items: [Item] {
        var items = timeline.tasks.map(Item.task)
        items.insert(.now, at: timeline.nowIndex)
        return items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items) { item in
                switch item {
                case .task(let task): row(task)
                case .now: NowMarker(now: now)
                }
            }
        }
        .animation(reduceMotion ? nil : Motion.standard, value: timeline.nowIndex)
    }

    private func row(_ task: TaskSnapshot) -> some View {
        let dot = TimelineDot(task.cardState)
        return HStack(alignment: .top, spacing: Spacing.sm) {
            TimeColumn {
                Text(Formatters.current.time(task.window.start))
                    .font(Font.app.timelineTime)
                    .monospacedDigit()
                    .foregroundStyle(Color.app.textTertiary)
            }
            .padding(.top, Spacing.md)
            LineColumn {
                DotView(dot: dot)
                    .padding(.top, Spacing.md + Sizes.timelineLine)
            }
            card(task)
                .opacity(dot.isFaded ? Sizes.timelineDoneOpacity : 1)
                .padding(.bottom, Spacing.sm)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("timeline." + task.name)
    }
}

/// The "now" line: NOW in the time column, then a flame line from the timeline to the right edge.
private struct NowMarker: View {
    let now: Date

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            TimeColumn {
                Text(Strings.Today.now)
                    .font(Font.app.pill)
                    .capsLabel()
                    .foregroundStyle(Color.app.flame)
            }
            HStack(spacing: 0) {
                LineColumn {}
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(Color.app.flame)
                            .frame(width: Sizes.timelineDot / 2, height: Sizes.nowLine)
                    }
                Rectangle()
                    .fill(Color.app.flame)
                    .frame(height: Sizes.nowLine)
            }
        }
        .frame(minHeight: Spacing.xl)
        .padding(.bottom, Spacing.sm)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Today.nowAt(Formatters.current.time(of: now)))
        .accessibilityIdentifier("timeline.now")
    }
}

/// The time column: as wide as the longest time ("10:00 PM") at the current text size, right-aligned.
private struct TimeColumn<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        Text(Formatters.current.time(TimeOfDay(22)))
            .font(Font.app.timelineTime)
            .monospacedDigit()
            .hidden()
            .accessibilityHidden(true)
            .overlay(alignment: .trailing) { content }
    }
}

/// The line down the timeline, as wide as a dot, with something placed on it.
private struct LineColumn<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(Color.app.border)
                .frame(width: Sizes.timelineLine)
                .frame(maxHeight: .infinity)
            content
        }
        .frame(width: Sizes.timelineDot)
        .accessibilityHidden(true)
    }
}

/// A streak's dot: done green, upcoming muted with a ring, missed red, skipped grey.
private struct DotView: View {
    let dot: TimelineDot

    var body: some View {
        switch dot {
        case .done: Circle().fill(Color.app.success).frame(width: Sizes.timelineDot, height: Sizes.timelineDot)
        case .missed: Circle().fill(Color.app.danger).frame(width: Sizes.timelineDot, height: Sizes.timelineDot)
        case .skipped: Circle().fill(Color.app.textTertiary).frame(width: Sizes.timelineDot, height: Sizes.timelineDot)
        case .upcoming:
            Circle()
                .fill(Color.app.surfaceMuted)
                .overlay { Circle().strokeBorder(Color.app.border, lineWidth: Sizes.borderWidth) }
                .frame(width: Sizes.timelineDot, height: Sizes.timelineDot)
        }
    }
}
