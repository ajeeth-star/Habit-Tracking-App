import SwiftUI

/// The celebration's confetti burst (design.md §1.6): small pieces in the bright colors shoot up from
/// the center and fall with gravity over about 1.5s. Drawn with Canvas + TimelineView, no packages.
/// Place it behind the flame; it draws outside its own frame.
struct ConfettiView: View {
    private struct Piece {
        var velocity: CGVector
        var spin: Double
        var size: CGSize
        var color: Color
        var isCircle: Bool
    }

    @State private var start = Date()
    @State private var pieces: [Piece] = (0..<Motion.confettiCount).map { _ in
        let angle = Double.random(in: -.pi * 0.85 ... -.pi * 0.15) // mostly upward
        let speed = Double.random(in: 380...720)
        return Piece(velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
                     spin: Double.random(in: -8...8),
                     size: CGSize(width: Double.random(in: 6...10), height: Double.random(in: 8...14)),
                     color: Color.app.confetti.randomElement() ?? Color.app.flame,
                     isCircle: Bool.random())
    }

    private static let gravity = 1100.0

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(start)
            Canvas { context, size in
                guard t < Motion.confettiDuration else { return }
                let origin = CGPoint(x: size.width / 2, y: size.height / 2)
                // Fade out over the last third.
                let fade = min(1, (Motion.confettiDuration - t) / (Motion.confettiDuration / 3))
                for piece in pieces {
                    let x = origin.x + piece.velocity.dx * t
                    let y = origin.y + piece.velocity.dy * t + 0.5 * Self.gravity * t * t
                    var shape = context
                    shape.opacity = fade
                    shape.translateBy(x: x, y: y)
                    shape.rotate(by: .radians(piece.spin * t))
                    let rect = CGRect(x: -piece.size.width / 2, y: -piece.size.height / 2,
                                      width: piece.size.width, height: piece.isCircle ? piece.size.width : piece.size.height)
                    let path = piece.isCircle ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: 2)
                    shape.fill(path, with: .color(piece.color))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
