import SwiftUI

/// The flame character (design.md §2b), drawn in code with `Canvas`: a teardrop body with 0–5 tongues,
/// a lighter core, a 3pt outline, and a face that shows its mood. It sways, breathes, and blinks.
///
/// The view is `size` × `size`; the body is drawn at the form's scale and stands on the bottom edge.
/// Glow, embers, and sparkles may spill outside the frame.
struct FlameCharacterView: View {
    let form: FlameForm
    var mood: FlameMood = .happy
    var size: CGFloat = Sizes.flameHeader
    /// The day streak, for VoiceOver ("… 23 day streak."). Nil leaves it out.
    var days: Int?
    /// False draws one still frame: no sway, breathing, or blinking (small copies).
    var animated = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var blinks = BlinkSchedule()

    /// The canvas is bigger than the frame so the glow and sparkles aren't cut off.
    private static let overflow: CGFloat = 1.7

    var body: some View {
        Group {
            if animated {
                TimelineView(.animation) { context in
                    canvas(at: context.date.timeIntervalSince(start))
                }
            } else {
                canvas(at: 0)
            }
        }
        .frame(width: size * Self.overflow, height: size * Self.overflow)
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(Formatters.current.flameAccessibility(form: form, mood: mood, days: days))
        .accessibilityAddTraits(.isImage)
    }

    private func canvas(at time: Double) -> some View {
        let moving = animated && !reduceMotion
        let drawing = FlameDrawing(
            look: FlameLook(form: form), mood: mood, frameSize: size, time: time, moving: moving,
            blink: animated ? blinks.closedAmount(at: time) : 0)
        return Canvas { context, canvasSize in
            drawing.draw(in: &context, canvasSize: canvasSize)
        }
    }
}

/// How each form looks (design.md §2b).
struct FlameLook {
    var scale: CGFloat
    var tongues: Int
    var body: Color
    var outline: Color
    /// A second, smaller layer inside the body (Inferno and Wildfire: orange inside red).
    var middle: Color?
    var core: Color
    /// Tongue tips in another color (Wildfire purple, Eternal white).
    var tips: Color?
    /// 0 = no glow, up to 3.
    var glow: Int
    var embers = false
    var sparkles = false
    var orbit = false

    init(form: FlameForm) {
        let app = Color.app
        switch form {
        case .ember:
            self.init(scale: 0.6, tongues: 0, body: app.flameLip, outline: app.flameEmberOutline,
                      core: app.flame, glow: 1)
        case .spark:
            self.init(scale: 0.75, tongues: 2, body: app.flame, outline: app.flameLip, core: app.flameSparkCore, glow: 0)
        case .flame:
            self.init(scale: 1, tongues: 3, body: app.flame, outline: app.flameLip, core: app.gold, glow: 0)
        case .blaze:
            self.init(scale: 1.1, tongues: 4, body: app.flame, outline: app.flameLip, core: app.gold, glow: 1)
        case .bonfire:
            self.init(scale: 1.2, tongues: 5, body: app.flame, outline: app.flameLip, core: app.gold, glow: 2,
                      embers: true)
        case .inferno:
            self.init(scale: 1.3, tongues: 5, body: app.danger, outline: app.dangerLip, middle: app.flame,
                      core: app.flameWhiteHot, glow: 3, embers: true)
        case .wildfire:
            self.init(scale: 1.4, tongues: 5, body: app.danger, outline: app.dangerLip, middle: app.flame,
                      core: app.flameWhiteHot, tips: app.purple, glow: 3, embers: true, sparkles: true)
        case .eternal:
            self.init(scale: 1.5, tongues: 5, body: app.info, outline: app.flameEternalOutline,
                      core: app.flameWhiteHot, tips: app.flameWhiteHot, glow: 3, sparkles: true, orbit: true)
        }
    }

    private init(scale: CGFloat, tongues: Int, body: Color, outline: Color, middle: Color? = nil, core: Color,
                 tips: Color? = nil, glow: Int, embers: Bool = false, sparkles: Bool = false, orbit: Bool = false) {
        self.scale = scale
        self.tongues = tongues
        self.body = body
        self.outline = outline
        self.middle = middle
        self.core = core
        self.tips = tips
        self.glow = glow
        self.embers = embers
        self.sparkles = sparkles
        self.orbit = orbit
    }
}

/// Random blinks every 3–6 seconds, decided once per flame.
private struct BlinkSchedule {
    private let starts: [Double]
    private let cycle: Double

    init() {
        var time = 0.0
        var starts: [Double] = []
        while time < 120 {
            time += Double.random(in: Motion.flameBlinkInterval)
            starts.append(time)
        }
        self.starts = starts
        cycle = time + Motion.flameBlinkInterval.lowerBound
    }

    /// 0 = eyes open, 1 = shut.
    func closedAmount(at time: Double) -> Double {
        let t = time.truncatingRemainder(dividingBy: cycle)
        guard let start = starts.last(where: { $0 <= t }), t - start < Motion.flameBlinkDuration else { return 0 }
        return sin(.pi * (t - start) / Motion.flameBlinkDuration)
    }
}

/// One frame of the flame. Shapes are laid out in a unit square (x and y from 0 to 1, y down) that is
/// mapped onto the body's box.
private struct FlameDrawing {
    let look: FlameLook
    let mood: FlameMood
    let frameSize: CGFloat
    let time: Double
    let moving: Bool
    /// 0 open … 1 shut.
    let blink: Double

    /// One flame tongue: where its base sits, how wide it is, and where its tip points.
    private struct Tongue {
        var baseX: CGFloat, baseY: CGFloat, halfWidth: CGFloat, tipX: CGFloat, tipY: CGFloat
    }

    private static let layouts: [Int: [Tongue]] = [
        2: [Tongue(baseX: 0.42, baseY: 0.5, halfWidth: 0.2, tipX: 0.36, tipY: 0.02),
            Tongue(baseX: 0.63, baseY: 0.56, halfWidth: 0.16, tipX: 0.76, tipY: 0.2)],
        3: [Tongue(baseX: 0.5, baseY: 0.5, halfWidth: 0.2, tipX: 0.5, tipY: 0),
            Tongue(baseX: 0.32, baseY: 0.58, halfWidth: 0.15, tipX: 0.18, tipY: 0.2),
            Tongue(baseX: 0.68, baseY: 0.58, halfWidth: 0.15, tipX: 0.82, tipY: 0.22)],
        4: [Tongue(baseX: 0.43, baseY: 0.5, halfWidth: 0.18, tipX: 0.4, tipY: 0),
            Tongue(baseX: 0.6, baseY: 0.52, halfWidth: 0.16, tipX: 0.66, tipY: 0.08),
            Tongue(baseX: 0.3, baseY: 0.6, halfWidth: 0.14, tipX: 0.13, tipY: 0.26),
            Tongue(baseX: 0.71, baseY: 0.6, halfWidth: 0.13, tipX: 0.88, tipY: 0.3)],
        5: [Tongue(baseX: 0.5, baseY: 0.48, halfWidth: 0.18, tipX: 0.5, tipY: -0.02),
            Tongue(baseX: 0.36, baseY: 0.54, halfWidth: 0.15, tipX: 0.27, tipY: 0.1),
            Tongue(baseX: 0.64, baseY: 0.54, halfWidth: 0.15, tipX: 0.74, tipY: 0.12),
            Tongue(baseX: 0.28, baseY: 0.62, halfWidth: 0.12, tipX: 0.08, tipY: 0.32),
            Tongue(baseX: 0.73, baseY: 0.62, halfWidth: 0.12, tipX: 0.93, tipY: 0.34)],
    ]

    // MARK: Layout

    /// The body's box: square, standing on the frame's bottom edge, centered.
    private func bodyBox(canvasSize: CGSize) -> CGRect {
        let breath = moving ? 1 + Motion.flameBreathAmount * sin(2 * .pi * time / Motion.flameBreathPeriod) : 1
        let side = frameSize * look.scale * 0.66 * breath
        let frameBottom = (canvasSize.height + frameSize) / 2
        let bounce = mood == .cheering && moving ? -abs(sin(time * .pi * 2)) * frameSize * 0.08 : 0
        return CGRect(x: (canvasSize.width - side) / 2, y: frameBottom - side + bounce, width: side, height: side)
    }

    // MARK: Drawing

    func draw(in context: inout GraphicsContext, canvasSize: CGSize) {
        let box = bodyBox(canvasSize: canvasSize)
        let p = { (x: CGFloat, y: CGFloat) in CGPoint(x: box.minX + x * box.width, y: box.minY + y * box.height) }
        let unit = box.width
        let outlineWidth = Sizes.flameOutline * min(1, frameSize / Sizes.flameHeader)
        let dim = mood == .sad

        var body = context
        if dim { body.opacity = 0.7 }

        drawGlow(in: &body, p: p, unit: unit)
        if look.orbit { drawOrbit(in: &body, p: p, unit: unit, front: false) }

        let tongues = swayedTongues()
        let shapes = bodyShapes(tongues: tongues, p: p)
        // The outline: every shape stroked wide, then filled on top, so only the outer edge shows.
        for shape in shapes {
            body.stroke(shape, with: .color(look.outline),
                        style: StrokeStyle(lineWidth: outlineWidth * 2, lineCap: .round, lineJoin: .round))
        }
        for shape in shapes { body.fill(shape, with: .color(look.body)) }

        if let middle = look.middle {
            let inner = tongues.map { scaled($0, by: 0.72) }
            for shape in bodyShapes(tongues: inner, p: p, inset: 0.06) { body.fill(shape, with: .color(middle)) }
        }
        if let tips = look.tips {
            for tongue in tongues { body.fill(tipShape(tongue, p: p), with: .color(tips)) }
        }
        body.fill(teardrop(cx: 0.5, cy: 0.77, r: 0.16, tipY: 0.5, p: p), with: .color(look.core))

        if look.embers { drawEmbers(in: &body, p: p, unit: unit) }
        if look.sparkles { drawSparkles(in: &body, p: p, unit: unit) }
        if look.orbit { drawOrbit(in: &body, p: p, unit: unit, front: true) }

        drawFace(in: &context, p: p, unit: unit)
    }

    /// The teardrop plus its tongues (or a taller teardrop alone for the Ember).
    private func bodyShapes(tongues: [Tongue], p: (CGFloat, CGFloat) -> CGPoint, inset: CGFloat = 0) -> [Path] {
        let r = 0.34 - inset
        let cy = 0.64 + inset * 0.6
        guard !tongues.isEmpty else {
            let sway = moving ? 0.03 * sin(time * 2.2) : 0
            return [teardrop(cx: 0.5, cy: cy, r: r, tipY: 0.08 + inset * 2, tipX: 0.5 + sway, p: p)]
        }
        return [teardrop(cx: 0.5, cy: cy, r: r, tipY: 0.3 + inset, p: p)] + tongues.map { tongueShape($0, p: p) }
    }

    private func swayedTongues() -> [Tongue] {
        let layout = Self.layouts[look.tongues] ?? []
        guard moving else { return layout }
        return layout.enumerated().map { index, tongue in
            var tongue = tongue
            let i = Double(index)
            tongue.tipX += 0.035 * sin(time * 2.4 + i * 1.7)
            tongue.tipY += 0.015 * sin(time * 3.1 + i * 0.9)
            return tongue
        }
    }

    /// A tongue shrunk toward its base, for the inner layer.
    private func scaled(_ tongue: Tongue, by factor: CGFloat) -> Tongue {
        var t = tongue
        t.halfWidth *= factor
        t.tipY = t.baseY - (t.baseY - t.tipY) * factor
        t.tipX = t.baseX + (t.tipX - t.baseX) * factor
        return t
    }

    /// A rounded bottom (a circle at `cy`, radius `r`) narrowing to a point at the top.
    private func teardrop(cx: CGFloat, cy: CGFloat, r: CGFloat, tipY: CGFloat, tipX: CGFloat? = nil,
                          p: (CGFloat, CGFloat) -> CGPoint) -> Path {
        let tipX = tipX ?? cx
        let k: CGFloat = 0.5523 // circle approximation with Bézier curves
        var path = Path()
        path.move(to: p(tipX, tipY))
        path.addCurve(to: p(cx + r, cy), control1: p(tipX + r * 0.35, tipY + (cy - tipY) * 0.35),
                      control2: p(cx + r, cy - r * 0.8))
        path.addCurve(to: p(cx, cy + r), control1: p(cx + r, cy + r * k), control2: p(cx + r * k, cy + r))
        path.addCurve(to: p(cx - r, cy), control1: p(cx - r * k, cy + r), control2: p(cx - r, cy + r * k))
        path.addCurve(to: p(tipX, tipY), control1: p(cx - r, cy - r * 0.8),
                      control2: p(tipX - r * 0.35, tipY + (cy - tipY) * 0.35))
        path.closeSubpath()
        return path
    }

    private func tongueShape(_ t: Tongue, p: (CGFloat, CGFloat) -> CGPoint) -> Path {
        let h = t.baseY - t.tipY
        var path = Path()
        path.move(to: p(t.baseX - t.halfWidth, t.baseY))
        path.addCurve(to: p(t.tipX, t.tipY), control1: p(t.baseX - t.halfWidth, t.baseY - h * 0.55),
                      control2: p(t.tipX - t.halfWidth * 0.15, t.tipY + h * 0.35))
        path.addCurve(to: p(t.baseX + t.halfWidth, t.baseY), control1: p(t.tipX + t.halfWidth * 0.35, t.tipY + h * 0.45),
                      control2: p(t.baseX + t.halfWidth, t.baseY - h * 0.4))
        path.closeSubpath()
        return path
    }

    /// The top part of a tongue, for colored tips.
    private func tipShape(_ t: Tongue, p: (CGFloat, CGFloat) -> CGPoint) -> Path {
        var tip = t
        tip.baseX = t.baseX + (t.tipX - t.baseX) * 0.6
        tip.baseY = t.baseY - (t.baseY - t.tipY) * 0.6
        tip.halfWidth = t.halfWidth * 0.32
        return tongueShape(tip, p: p)
    }

    // MARK: Effects

    private func drawGlow(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, unit: CGFloat) {
        let level = look.glow + (mood == .proud ? 1 : 0)
        guard level > 0 else { return }
        let center = p(0.5, 0.6)
        let l = CGFloat(level)
        for (radius, opacity) in [(0.48 + 0.04 * l, 0.1 + 0.03 * l), (0.56 + 0.04 * l, 0.06 + 0.02 * l)].reversed() {
            let r = radius * unit
            context.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                         with: .color(look.body.opacity(opacity)))
        }
    }

    /// Bonfire and up: little embers drifting up from the tips and fading.
    private func drawEmbers(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, unit: CGFloat) {
        let count = 6
        for i in 0..<count {
            let offset = Double(i) / Double(count)
            let progress = moving ? (time / 2.4 + offset).truncatingRemainder(dividingBy: 1) : offset
            let drift = moving ? 0.03 * sin(time * 2 + Double(i)) : 0
            let x = 0.5 + (Self.jitter(i) - 0.5) * 0.7 + drift
            let y = 0.3 - progress * 0.6
            let r = 0.028 * (1 - progress * 0.6) * unit
            let center = p(x, y)
            let color = i.isMultiple(of: 2) ? Color.app.gold : Color.app.flame
            context.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                         with: .color(color.opacity(1 - progress)))
        }
    }

    /// Wildfire and up: four-pointed sparkles twinkling around the flame.
    private func drawSparkles(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, unit: CGFloat) {
        let spots: [(CGFloat, CGFloat)] = [(0.08, 0.12), (0.94, 0.05), (1.02, 0.55), (-0.04, 0.6)]
        for (i, spot) in spots.enumerated() {
            let twinkle = moving ? 0.55 + 0.45 * sin(time * 3 + Double(i) * 2) : 0.8
            let color = i.isMultiple(of: 2) ? Color.app.flameWhiteHot : look.tips ?? Color.app.purple
            context.fill(star(at: p(spot.0, spot.1), radius: 0.07 * unit * twinkle), with: .color(color))
        }
    }

    /// Eternal: sparkles circling the flame. The ones behind it are drawn before the body.
    private func drawOrbit(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, unit: CGFloat,
                           front: Bool) {
        let count = 5
        for i in 0..<count {
            let angle = (moving ? time * 1.2 : 0.4) + Double(i) * 2 * .pi / Double(count)
            let inFront = sin(angle) > 0
            guard inFront == front else { continue }
            let center = p(0.5 + 0.72 * cos(angle), 0.62 + 0.2 * sin(angle))
            let color = i.isMultiple(of: 2) ? Color.app.flameWhiteHot : Color.app.info
            context.fill(star(at: center, radius: 0.06 * unit * (inFront ? 1 : 0.7)),
                         with: .color(color.opacity(inFront ? 1 : 0.6)))
        }
    }

    private func star(at center: CGPoint, radius r: CGFloat) -> Path {
        let pinch = r * 0.18
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - r))
        path.addQuadCurve(to: CGPoint(x: center.x + r, y: center.y), control: CGPoint(x: center.x + pinch, y: center.y - pinch))
        path.addQuadCurve(to: CGPoint(x: center.x, y: center.y + r), control: CGPoint(x: center.x + pinch, y: center.y + pinch))
        path.addQuadCurve(to: CGPoint(x: center.x - r, y: center.y), control: CGPoint(x: center.x - pinch, y: center.y + pinch))
        path.addQuadCurve(to: CGPoint(x: center.x, y: center.y - r), control: CGPoint(x: center.x - pinch, y: center.y - pinch))
        path.closeSubpath()
        return path
    }

    /// A fixed pseudo-random number in 0…1 for each index.
    private static func jitter(_ i: Int) -> Double {
        let x = sin(Double(i) * 12.9898) * 43758.5453
        return x - x.rounded(.down)
    }

    // MARK: Face

    private func drawFace(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, unit: CGFloat) {
        let ink = Color.app.textOnBright
        let eyeWidth: CGFloat = mood == .worried ? 0.12 : 0.1
        let eyeHeight: CGFloat = mood == .worried ? 0.16 : 0.14
        let line = StrokeStyle(lineWidth: max(1.2, 0.035 * unit), lineCap: .round, lineJoin: .round)
        let eyes: [CGFloat] = [0.39, 0.61]
        let eyeY: CGFloat = 0.62

        for (index, x) in eyes.enumerated() {
            let center = p(x, eyeY)
            let w = eyeWidth * unit, h = eyeHeight * unit
            switch mood {
            case .proud:
                // Happy arcs: ∩
                var arc = Path()
                arc.move(to: CGPoint(x: center.x - w / 2, y: center.y + h * 0.15))
                arc.addQuadCurve(to: CGPoint(x: center.x + w / 2, y: center.y + h * 0.15),
                                 control: CGPoint(x: center.x, y: center.y - h * 0.55))
                context.stroke(arc, with: .color(ink), style: line)
            case .sleepy:
                // Closed: a gentle downward curve
                var lid = Path()
                lid.move(to: CGPoint(x: center.x - w / 2, y: center.y))
                lid.addQuadCurve(to: CGPoint(x: center.x + w / 2, y: center.y),
                                 control: CGPoint(x: center.x, y: center.y + h * 0.45))
                context.stroke(lid, with: .color(ink), style: line)
            case .cheering:
                // ^ ^
                var caret = Path()
                caret.move(to: CGPoint(x: center.x - w / 2, y: center.y + h * 0.2))
                caret.addLine(to: CGPoint(x: center.x, y: center.y - h * 0.3))
                caret.addLine(to: CGPoint(x: center.x + w / 2, y: center.y + h * 0.2))
                context.stroke(caret, with: .color(ink), style: line)
            case .happy, .worried, .sad:
                drawOpenEye(in: &context, center: center, width: w, height: h, unit: unit, line: line,
                            isOuterLeft: index == 0)
            }
        }

        drawMouth(in: &context, p: p, unit: unit, line: line)

        if mood == .worried { drawSweatDrop(in: &context, p: p, unit: unit) }
        if mood == .sleepy { drawZ(in: &context, p: p, unit: unit) }
    }

    private func drawOpenEye(in context: inout GraphicsContext, center: CGPoint, width w: CGFloat, height h: CGFloat,
                             unit: CGFloat, line: StrokeStyle, isOuterLeft: Bool) {
        let ink = Color.app.textOnBright
        // Blinking squashes the eye to a line.
        let open = max(0.08, 1 - blink)
        let eye = CGRect(x: center.x - w / 2, y: center.y - h / 2 * open, width: w, height: h * open)
        var eyeContext = context
        var lidLine: Path?
        if mood == .sad {
            // Half closed: only the lower part shows, under a lid that droops toward the outside.
            var visible = Path()
            let outerDrop = h * 0.15
            let leftY = center.y - (isOuterLeft ? -outerDrop : 0) - h * 0.05
            let rightY = center.y - (isOuterLeft ? 0 : -outerDrop) - h * 0.05
            visible.move(to: CGPoint(x: eye.minX - 2, y: leftY))
            visible.addLine(to: CGPoint(x: eye.maxX + 2, y: rightY))
            visible.addLine(to: CGPoint(x: eye.maxX + 2, y: eye.maxY + 2))
            visible.addLine(to: CGPoint(x: eye.minX - 2, y: eye.maxY + 2))
            visible.closeSubpath()
            eyeContext.clip(to: visible)
            var lid = Path()
            lid.move(to: CGPoint(x: eye.minX, y: leftY))
            lid.addLine(to: CGPoint(x: eye.maxX, y: rightY))
            lidLine = lid
        }
        eyeContext.fill(Path(ellipseIn: eye), with: .color(Color.app.flameEye))
        eyeContext.stroke(Path(ellipseIn: eye), with: .color(ink), lineWidth: max(0.8, 0.012 * unit))
        if open > 0.4 {
            let pupilRadius = w * (mood == .worried ? 0.22 : 0.3)
            let pupilY = mood == .worried ? center.y - h * 0.05 : center.y + h * 0.12
            let pupil = CGRect(x: center.x - pupilRadius, y: pupilY - pupilRadius * open,
                               width: pupilRadius * 2, height: pupilRadius * 2 * open)
            eyeContext.fill(Path(ellipseIn: pupil), with: .color(ink))
        }
        if let lidLine { context.stroke(lidLine, with: .color(ink), style: line) }
    }

    private func drawMouth(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, unit: CGFloat,
                           line: StrokeStyle) {
        let ink = Color.app.textOnBright
        var mouth = Path()
        switch mood {
        case .happy:
            mouth.move(to: p(0.45, 0.76))
            mouth.addQuadCurve(to: p(0.55, 0.76), control: p(0.5, 0.82))
            context.stroke(mouth, with: .color(ink), style: line)
        case .proud, .cheering:
            // A big open smile; wider when cheering, with a tongue.
            let half: CGFloat = mood == .cheering ? 0.09 : 0.08
            let depth: CGFloat = mood == .cheering ? 0.92 : 0.88
            mouth.move(to: p(0.5 - half, 0.75))
            mouth.addLine(to: p(0.5 + half, 0.75))
            mouth.addQuadCurve(to: p(0.5 - half, 0.75), control: p(0.5, depth))
            mouth.closeSubpath()
            context.fill(mouth, with: .color(ink))
            if mood == .cheering {
                var tongue = context
                tongue.clip(to: mouth)
                let center = p(0.5, 0.83)
                let r = 0.045 * unit
                tongue.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r * 0.6, width: r * 2, height: r * 1.6)),
                            with: .color(Color.app.danger))
            }
        case .sleepy:
            let center = p(0.5, 0.78)
            let r = 0.028 * unit
            context.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r * 1.2, width: r * 2, height: r * 2.4)),
                         with: .color(ink))
        case .worried:
            mouth.move(to: p(0.43, 0.78))
            mouth.addQuadCurve(to: p(0.5, 0.78), control: p(0.465, 0.75))
            mouth.addQuadCurve(to: p(0.57, 0.78), control: p(0.535, 0.81))
            context.stroke(mouth, with: .color(ink), style: line)
        case .sad:
            mouth.move(to: p(0.45, 0.8))
            mouth.addQuadCurve(to: p(0.55, 0.8), control: p(0.5, 0.74))
            context.stroke(mouth, with: .color(ink), style: line)
        }
    }

    private func drawSweatDrop(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, unit: CGFloat) {
        let slide = moving ? 0.04 * (time / 1.6).truncatingRemainder(dividingBy: 1) : 0
        let drop = teardrop(cx: 0.78, cy: 0.55 + slide, r: 0.045, tipY: 0.47 + slide, p: p)
        context.fill(drop, with: .color(Color.app.info))
        context.stroke(drop, with: .color(Color.app.infoLip), lineWidth: max(0.8, 0.012 * unit))
    }

    /// The sleepy "z" floats up and fades, every few seconds.
    private func drawZ(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, unit: CGFloat) {
        let progress = moving ? (time / Motion.flameSleepCycle).truncatingRemainder(dividingBy: 1) : 0.3
        let point = p(0.84 + 0.06 * progress, 0.28 - 0.25 * progress)
        var zContext = context
        zContext.opacity = moving ? 1 - progress : 1
        zContext.translateBy(x: point.x, y: point.y)
        let scale = unit / 100
        zContext.scaleBy(x: scale, y: scale)
        zContext.draw(Text(Strings.Flame.sleepZ).font(Font.app.flameSleepZ).foregroundStyle(Color.app.textPrimary), at: .zero)
    }
}
