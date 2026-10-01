import SwiftUI

/// Camera → preview → streak celebration, presented full screen from a "Check in" button.
/// On Submit it hands the checked-in task to `onCheckedIn`; the screen that opened the flow decides
/// when to show it (Home waits until the celebration has closed, so the card closes in front of you).
/// Nothing is saved in this phase.
struct CheckInFlowView: View {
    let task: TaskSnapshot
    /// When the check-in happens (sample "now" in this phase).
    let now: Date
    var onCheckedIn: (TaskSnapshot) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var step = Step.camera

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
                    onCheckedIn(task.checkedIn(at: now))
                    step = .celebration
                })
        case .celebration:
            StreakCelebrationView(result: task.checkInResult(at: now), onDone: { dismiss() })
        }
    }
}
