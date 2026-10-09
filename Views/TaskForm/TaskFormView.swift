import SwiftUI

/// Create or edit a task, shown as a sheet (design.md §4.3), saved through the shared `TaskStore`.
struct TaskFormView: View {
    enum Mode {
        case create
        case edit(TaskSnapshot)
    }

    /// The form's editable values.
    typealias Draft = StreakDraft

    /// What the edit form's bottom buttons can do to the habit.
    enum Removal: Hashable {
        case archive, delete
    }

    let mode: Mode
    /// Called after Archive or Delete is confirmed, once the form has closed. Edit mode only.
    var onRemove: (Removal) -> Void = { _ in }
    /// Where the form starts scrolled to; `.bottom` shows the edit buttons (the Design Gallery uses this).
    var scrollAnchor = UnitPoint.top

    @Environment(\.dismiss) private var dismiss
    @Environment(TaskStore.self) private var store
    @State private var draft: Draft
    @State private var editingTime: TimeField?
    @State private var confirming: Removal?
    /// Set when a dialog's Archive / Delete is tapped; acted on once the dialog has closed.
    @State private var confirmed: Removal?
    /// Once an icon is tapped (or when editing), the icon stops following the name.
    @State private var iconPickedByHand: Bool
    /// A brand-new streak picks its color when the form first appears.
    @State private var needsDefaultColor: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private enum TimeField { case start, end }
    private let format = Formatters.current

    init(mode: Mode, draft: Draft? = nil, scrollAnchor: UnitPoint = .top,
         onRemove: @escaping (Removal) -> Void = { _ in }) {
        self.mode = mode
        self.scrollAnchor = scrollAnchor
        self.onRemove = onRemove
        let isCreate: Bool
        if case .create = mode { isCreate = true } else { isCreate = false }
        var start = draft ?? Self.initialDraft(for: mode)
        // A new streak that arrives with a name already filled in still gets its icon guessed.
        if isCreate, start.icon == StreakIcon.fallback {
            start.icon = StreakIcon.guess(for: start.name)
        }
        _draft = State(initialValue: start)
        _iconPickedByHand = State(initialValue: !isCreate)
        _needsDefaultColor = State(initialValue: isCreate && draft == nil)
    }

    static func initialDraft(for mode: Mode) -> Draft {
        switch mode {
        case .create:
            Draft()
        case .edit(let task):
            // Days and skips start from next week's, if a change is already waiting for Monday.
            Draft(name: task.name, days: Set(task.nextWeek?.days ?? task.days), window: task.window,
                  skips: task.nextWeek?.skipsPerWeek ?? task.skipsPerWeek, color: task.color, icon: task.icon)
        }
    }

    /// Saves the new streak, or the edit (days and skips from next Monday; context.md §3).
    private func save() {
        var cleaned = draft
        cleaned.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let original {
            store.update(original.id, with: cleaned)
        } else {
            store.create(cleaned)
        }
        dismiss()
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    nameField
                    styleField
                    daysField
                    timeField
                    skipsField
                    ChunkyButton(isEditing ? Strings.Form.save : Strings.Form.create, action: save)
                        .accessibilityIdentifier("form.save")
                        .disabled(!isValid)
                    if isEditing {
                        removeButtons
                            .padding(.top, Spacing.xxl - Spacing.xl)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .defaultScrollAnchor(scrollAnchor)
        }
        .background(Color.app.background)
        .dialogCover(isPresented: confirmingBinding, onDismiss: removeIfConfirmed) {
            removalDialog
        }
        .onChange(of: draft.days) { _, days in
            draft.skips = min(draft.skips, days.count)
        }
        .onChange(of: draft.name) { _, name in
            if name.count > Sizes.maxTaskNameLength {
                draft.name = String(name.prefix(Sizes.maxTaskNameLength))
            }
            if !iconPickedByHand {
                draft.icon = StreakIcon.guess(for: name)
            }
        }
        .onAppear {
            guard needsDefaultColor else { return }
            needsDefaultColor = false
            draft.color = StreakColor.nextUnused(after: store.active.map(\.color))
        }
    }

    // MARK: Archive and delete (edit mode)

    private var removeButtons: some View {
        VStack(spacing: Spacing.xs) {
            ChunkyButton(style: .secondary, Strings.Form.archiveHabit) { withoutAnimation { confirming = .archive } }
            ChunkyButton(style: .danger, Strings.Form.deleteHabit) { withoutAnimation { confirming = .delete } }
        }
    }

    private var confirmingBinding: Binding<Bool> {
        Binding { confirming != nil } set: { if !$0 { confirming = nil } }
    }

    @ViewBuilder private var removalDialog: some View {
        let name = original?.name ?? draft.name
        switch confirming {
        case .archive:
            AppDialog(title: Strings.Dialog.archiveTitle(name), message: Strings.Dialog.archiveBody,
                      actionTitle: Strings.Dialog.archive, actionStyle: .neutral) { confirmed = .archive }
        case .delete:
            AppDialog(title: Strings.Dialog.deleteTitle(name), message: Strings.Dialog.deleteBody,
                      actionTitle: Strings.Dialog.delete, actionStyle: .destructive) { confirmed = .delete }
        case nil:
            EmptyView()
        }
    }

    /// After the dialog closes: hand the archive or delete to whoever opened the form, and close it.
    private func removeIfConfirmed() {
        guard let removal = confirmed else { return }
        confirmed = nil
        onRemove(removal)
        dismiss()
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
            .foregroundStyle(Color.app.flame)
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

    private var styleField: some View {
        field(Strings.StreakStyle.section) {
            StreakStylePicker(color: $draft.color, icon: $draft.icon) { iconPickedByHand = true }
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
            .softHaptic(trigger: draft.skips)
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
            .strokeBorder(Color.app.border, lineWidth: Sizes.borderWidth)
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
                    .strokeBorder(editingTime == which ? Color.app.flame : Color.app.border,
                                  lineWidth: editingTime == which ? Sizes.emphasisStroke : Sizes.borderWidth)
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
                .foregroundStyle(enabled ? Color.app.flame : Color.app.textTertiary)
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
