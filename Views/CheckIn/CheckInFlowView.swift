import SwiftUI

/// Camera → preview → celebration sequence, presented full screen from a "Check in" button.
/// On Submit the check-in and its photo are saved straight away (if the window is still open — `CheckInRule`),
/// then the celebration shows what changed.
struct CheckInFlowView: View {
    let task: TaskSnapshot

    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @Environment(TaskStore.self) private var store
    @Environment(DayStreakStore.self) private var dayStreak
    @State private var step = Step.camera
    @State private var photo: UIImage?
    @State private var result: CheckInResult?
    /// Worked out on Submit: whether this check-in completes the day (celebration steps 2 and 3).
    @State private var dayChange: DayStreakChange?
    @State private var formBefore = FlameForm.ember

    private enum Step { case camera, preview, closed, celebration }

    var body: some View {
        switch step {
        case .camera:
            CameraView(
                taskName: task.name,
                closesAt: task.window.end,
                onClose: { dismiss() },
                onCapture: { image in
                    photo = image
                    step = .preview
                })
        case .preview:
            PhotoPreviewView(
                taskName: task.name,
                closesAt: task.window.end,
                image: photo.map(Image.init(uiImage:)),
                onRetake: { step = .camera },
                onSubmit: submit)
        case .closed:
            CameraView(taskName: task.name, closesAt: task.window.end, windowClosed: true,
                       onClose: { dismiss() }, onCapture: { _ in })
        case .celebration:
            if let result {
                StreakCelebrationView(result: result, dayChange: dayChange, form: formBefore, onDone: { dismiss() })
            }
        }
    }

    private func submit() {
        let now = store.now()
        let before = store.task(task.id) ?? task
        formBefore = dayStreak.state.form
        let change = store.previewDayStreak(checkingIn: task.id, at: now)
        guard store.checkIn(task.id, photo: photo, at: now) else {
            step = .closed
            return
        }
        SoundPlayer.shared.play(.checkIn, enabled: settings.sounds)
        dayChange = change
        result = CheckInResult(before: before, after: store.task(task.id) ?? before.checkedIn(at: now))
        step = .celebration
    }
}

extension CheckInResult {
    /// What the celebration shows, from the streak just before and just after the check-in.
    init(before: TaskSnapshot, after: TaskSnapshot) {
        let wasSkipped = if case .scheduled(_, .skipped) = before.today { true } else { false }
        self.init(taskName: after.name, color: after.color, previousStreakDays: before.streak.totalCheckIns,
                  streak: after.streak, remainingThisWeek: after.scheduledDaysAfterToday.count,
                  refundedSkipsLeft: wasSkipped ? after.skipsLeft : nil)
    }
}
