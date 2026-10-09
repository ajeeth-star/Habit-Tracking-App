import SwiftUI

/// What the flame says (design.md §2b): `surface` fill, 2pt `border`, `Radius.lg`, with a small pointer on
/// its top edge pointing up at the flame.
struct SpeechBubble: View {
    let text: String
    /// Where the pointer sits along the top edge, from the leading edge. Nil centers it.
    var pointerX: CGFloat?
    /// Centered text (the empty state, the "streak ended" screen) instead of leading.
    var centered = false

    var body: some View {
        Text(text)
            .font(Font.app.subhead)
            .foregroundStyle(Color.app.textPrimary)
            .multilineTextAlignment(centered ? .center : .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
            .background {
                let shape = BubbleShape(pointerX: pointerX)
                shape.fill(Color.app.surface)
                    .overlay { shape.stroke(Color.app.border, lineWidth: Sizes.borderWidth) }
            }
            .padding(.top, Sizes.bubblePointerHeight)
            .contentTransition(.opacity)
    }
}

/// A rounded rectangle with a triangle pointer on top, drawn as one outline.
private struct BubbleShape: Shape {
    var pointerX: CGFloat?

    func path(in rect: CGRect) -> Path {
        let r = Radius.lg
        let w = Sizes.bubblePointerWidth
        let h = Sizes.bubblePointerHeight
        let tipX = min(max(pointerX ?? rect.midX, rect.minX + r + w / 2), rect.maxX - r - w / 2)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        path.addLine(to: CGPoint(x: tipX - w / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: tipX, y: rect.minY - h))
        path.addLine(to: CGPoint(x: tipX + w / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + r), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - r, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - r), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addQuadCurve(to: CGPoint(x: rect.minX + r, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
