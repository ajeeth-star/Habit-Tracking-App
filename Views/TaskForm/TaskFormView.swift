import SwiftUI

/// Create or edit a task, shown as a sheet (design.md §4.3). Nothing is saved in this phase.
struct TaskFormView: View {
    enum Mode {
        case create
        case edit(TaskSnapshot)
    }

    /// The form's editable values.
    struct Draft: Equatable {
        var name = ""
        var days: Set<Weekday> = []
        var window = TimeWindow(start: TimeOfDay(7), end: TimeOfDay(9))
        var skips = 0
    }

    let mode: Mode

    @Environment(\.dismiss) private var dismiss
    @State private var draft: Draft
    @State private var editingTime: TimeField?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private enum TimeField { case start, end }
    private let format = Formatters.current

    init(mode: Mode, draft: Draft? = nil) {
        self.mode = mode
        _draft = State(initialValue: draft ?? Self.initialDraft(for: mode))
    }

    static func initialDraft(for mode: Mode) -> Draft {
        switch mode {
        case .create:
            Draft()
        case .edit(let task):
            Draft(name: task.name, days: Set(task.days), window: task.window, skips: task.skipsPerWeek)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    nameField
                    daysField
                    timeField
                    skipsField
                    PrimaryButton(isEditing ? Strings.Form.save : Strings.Form.create) { dismiss() }
                        .disabled(!isValid)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.app.background)
        .onChange(of: draft.days) { _, days in
            draft.skips = min(draft.skips, days.count)
        }
        .onChange(of: draft.name) { _, name in
            if name.count > Sizes.maxTaskNameLength {
                draft.name = String(name.prefix(Sizes.maxTaskNameLength))
            }
        }
    }

    // MARK: Top bar

    @ViewBuilder private var topBar: some View {
        let title = Text(isEditing ? Strings.Form.editTitle : Strings.Form.newTitle)
            .font(Font.app.cardTitle)
            .foregroundStyle(Color.app.textPrimary)
            .accessibilityAddTraits(.isHeader)

        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // No room for both on one line: Cancel on top, the title below it.
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Button { dismiss() } label: { cancelLabel }
                    title
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Cancel on the left, the title centered, and an invisible copy of Cancel on the right for balance.
                HStack(spacing: Spacing.xs) {
                    Button { dismiss() } label: { cancelLabel }
                    title
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    cancelLabel
                        .hidden()
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xs)
    }

    private var cancelLabel: some View {
        Text(Strings.Form.cancel)
            .font(Font.app.body)
            .foregroundStyle(Color.app.accentText)
            .fixedSize()
            .frame(minHeight: Sizes.tapTarget)
            .contentShape(Rectangle())
    }

    // MARK: Fields

    private var nameField: some View {
        field(Strings.Form.name) {
            TextField(Strings.Form.namePlaceholder, text: $draft.name)
                .font(Font.app.body)
                .foregroundStyle(Color.app.textPrimary)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
                .padding(Sizes.fieldPadding)
                .background(Color.app.surface, in: .rounded(Radius.md))
                .overlay(outline)
        }
    }

    private var daysField: some View {
        field(Strings.Form.whichDays) {
            HStack(spacing: 0) {
                ForEach(Weekday.allCases) { day in
                    DayChip(day: day, isSelected: draft.days.contains(day)) {
                        if draft.days.contains(day) {
                            draft.days.remove(day)
                        } else {
                            draft.days.insert(day)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            if let original, draft.days != Set(original.days) {
                note(format.nextWeekDaysNote(new: draft.days.sorted(), current: original.days))
            }
        }
    }

    private var timeField: some View {
        field(Strings.Form.timeWindow) {
            AdaptiveStack {
                timeBox(Strings.Form.from, draft.window.start, .start)
                timeBox(Strings.Form.to, draft.window.end, .end)
            }
            if let editingTime {
                DatePicker("", selection: timeBinding(editingTime), displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
            }
            if !draft.window.isValid {
                Text(Strings.Form.endBeforeStart)
                    .font(Font.app.meta)
                    .foregroundStyle(Color.app.danger)
            }
        }
    }

    private var skipsField: some View {
        field(Strings.Form.skipsPerWeek) {
            HStack {
                stepperButton("minus", Strings.Form.decreaseSkips, enabled: draft.skips > 0) { draft.skips -= 1 }
                Spacer()
                Text("\(draft.skips)")
                    .font(Font.app.statValue)
                    .foregroundStyle(Color.app.textPrimary)
                    .contentTransition(.numericText())
                Spacer()
                stepperButton("plus", Strings.Form.increaseSkips, enabled: draft.skips < draft.days.count) {
                    draft.skips += 1
                }
            }
            .background(Color.app.surface, in: .rounded(Radius.md))
            .overlay(outline)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Strings.Form.skipsPerWeek)
            .accessibilityValue("\(draft.skips)")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: if draft.skips < draft.days.count { draft.skips += 1 }
                case .decrement: if draft.skips > 0 { draft.skips -= 1 }
                @unknown default: break
                }
            }

            note(format.skipHelper(taskName: draft.name, skips: draft.skips, dayCount: draft.days.count))
            if let original, draft.skips != original.skipsPerWeek {
                note(format.nextWeekSkipsNote(new: draft.skips, current: original.skipsPerWeek))
            }
        }
    }

    // MARK: Building blocks

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(Font.app.caption)
                .foregroundStyle(Color.app.textSecondary)
            content()
        }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(Font.app.meta)
            .foregroundStyle(Color.app.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var outline: some View {
        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
            .strokeBorder(Color.app.separator, lineWidth: Sizes.hairline)
    }

    private func timeBox(_ label: String, _ time: TimeOfDay, _ which: TimeField) -> some View {
        Button {
            withAnimation { editingTime = editingTime == which ? nil : which }
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(label)
                    .font(Font.app.caption)
                    .foregroundStyle(Color.app.textTertiary)
                Text(format.time(time))
                    .font(Font.app.body)
                    .monospacedDigit()
                    .foregroundStyle(Color.app.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Sizes.fieldPadding)
            .background(Color.app.surface, in: .rounded(Radius.md))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(editingTime == which ? Color.app.accent : Color.app.separator,
                                  lineWidth: editingTime == which ? Sizes.emphasisStroke : Sizes.hairline)
            }
            .contentShape(.rounded(Radius.md))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private func stepperButton(_ symbol: String, _ label: String, enabled: Bool,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(Font.app.button)
                .foregroundStyle(enabled ? Color.app.accentText : Color.app.textTertiary)
                .frame(width: Sizes.tapTarget, height: Sizes.tapTarget)
                .contentShape(Rectangle())
        }
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private func timeBinding(_ which: TimeField) -> Binding<Date> {
        Binding {
            let time = which == .start ? draft.window.start : draft.window.end
            return Calendar.current.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: .now) ?? .now
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            let time = TimeOfDay(parts.hour ?? 0, parts.minute ?? 0)
            if which == .start { draft.window.start = time } else { draft.window.end = time }
        }
    }

    // MARK: State

    private var isEditing: Bool { original != nil }

    private var original: TaskSnapshot? {
        if case .edit(let task) = mode { task } else { nil }
    }

    private var isValid: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !draft.days.isEmpty
            && draft.window.isValid
    }
}
