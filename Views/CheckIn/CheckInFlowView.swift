import SwiftUI

/// Camera → preview → celebration sequence, presented full screen from a "Check in" button.
/// On Submit it hands the checked-in task to `onCheckedIn`; the screen that opened the flow decides
/// when to show it (Home waits until the celebration has closed, so the card closes in front of you).
/// Nothing is saved in this phase.
struct CheckInFlowView: View {
    let task: TaskSnapshot
    /// When the check-in happens (sample "now" in this phase).
    let now: Date
    var onCheckedIn: (TaskSnapshot) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @Environment(TaskStore.self) private var store
    @Environment(DayStreakStore.self) private var dayStreak
    @State private var step = Step.camera
    /// Worked out on Submit: whether this check-in completes the day (celebration steps 2 and 3).
    @State private var dayChange: DayStreakChange?
    @State private var formBefore = FlameForm.ember

    private enum Step { case camera, preview, celebration }

    var body: some View {
        switch step {
        case .camera:
            CameraView(
                taskName: task.name,
                closesAt: task.window.end,
                onClose: { dismiss() },
                onCapture: { step = .preview })
        case .preview:
            PhotoPreviewView(
                taskName: task.name,
                closesAt: task.window.end,
                onRetake: { step = .camera },
                onSubmit: {
                    SoundPlayer.shared.play(.checkIn, enabled: settings.sounds)
                    let checkedIn = task.checkedIn(at: now)
                    formBefore = dayStreak.state.form
                    dayChange = dayStreak.preview(
                        tasks: store.tasks.map { $0.id == checkedIn.id ? checkedIn : $0 }, now: now)
                    onCheckedIn(checkedIn)
                    step = .celebration
                })
        case .celebration:
            StreakCelebrationView(result: task.checkInResult(at: now), dayChange: dayChange, form: formBefore,
                                  onDone: { dismiss() })
        }
    }
}
