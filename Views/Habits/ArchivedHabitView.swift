import SwiftUI

/// An archived habit (design.md §4.11): its best streak and photos kept, with Restore and
/// Delete permanently.
struct ArchivedHabitView: View {
    let task: TaskSnapshot

    @Environment(TaskStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingDelete = false
    @State private var deleteConfirmed = false

    private let format = Formatters.current

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(task.name)
                        .font(Font.app.screenTitle)
                        .foregroundStyle(Color.app.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(format.schedule(days: task.days, window: task.window))
                        .font(Font.app.meta)
                        .foregroundStyle(Color.app.textSecondary)
                    Text(Strings.Habits.archived)
                        .font(Font.app.caption)
                        .foregroundStyle(Color.app.textTertiary)
                }

                AdaptiveStack(spacing: Spacing.sm) {
                    StatTile(label: Strings.Habits.bestStreak,
                             value: format.streakCompact(task.best, mode: settings.streakDisplay))
                    StatTile(label: Strings.Habits.photos, value: "\(task.checkIns.count)")
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Spacing.md)

                VStack(spacing: Spacing.xs) {
                    ChunkyButton(Strings.Habits.restore) {
                        // Leave first, so this screen doesn't turn into the task screen on the way out.
                        let id = task.id
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { store.restore(id) }
                    }
                    ChunkyButton(style: .danger, Strings.Habits.deletePermanently) {
                        withoutAnimation { confirmingDelete = true }
                    }
                }
                .padding(.top, Spacing.xl)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.app.background)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(Font.app.button)
                        .foregroundStyle(Color.app.flame)
                        .frame(minWidth: Sizes.tapTarget, minHeight: Sizes.tapTarget, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Strings.Detail.back)
            }
        }
        .dialogCover(isPresented: $confirmingDelete, onDismiss: deleteIfConfirmed) {
            AppDialog(title: Strings.Dialog.deleteTitle(task.name), message: Strings.Dialog.deleteBody,
                      actionTitle: Strings.Dialog.delete, actionStyle: .destructive) { deleteConfirmed = true }
        }
    }

    /// After the dialog closes: leave this screen, then delete.
    private func deleteIfConfirmed() {
        guard deleteConfirmed else { return }
        let id = task.id
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { store.delete(id) }
    }
}
