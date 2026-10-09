import SwiftUI

/// The card look (design.md §2): a fill with a 2pt border and a 5pt "lip" along the bottom.
/// Tappable cards use `ChunkyCardButtonStyle` and press down 3pt.
struct ChunkyCardBackground: ViewModifier {
    var fill = Color.app.surface
    var lip = Color.app.border
    /// The 2pt outline; none on bright cards (the hero).
    var outline: Color? = Color.app.border
    var pressed = false

    func body(content: Content) -> some View {
        content
            .background(fill, in: .rounded(Radius.lg))
            .overlay {
                if let outline {
                    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                        .strokeBorder(outline, lineWidth: Sizes.borderWidth)
                }
            }
            .offset(y: pressed ? Sizes.cardPress : 0)
            .background(alignment: .bottom) {
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(lip)
                    .offset(y: Sizes.cardLip)
            }
            .padding(.bottom, Sizes.cardLip)
    }
}

extension View {
    /// A chunky card that doesn't press (or whose inner buttons do the pressing).
    func chunkyCard(fill: Color = Color.app.surface, lip: Color = Color.app.border,
                    outline: Color? = Color.app.border) -> some View {
        modifier(ChunkyCardBackground(fill: fill, lip: lip, outline: outline))
    }
}

/// A whole card as one button: it presses down 3pt while touched.
struct ChunkyCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Styled(configuration: configuration)
    }

    private struct Styled: View {
        let configuration: Configuration
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            configuration.label
                .contentShape(.rounded(Radius.lg))
                .modifier(ChunkyCardBackground(pressed: configuration.isPressed && !reduceMotion))
                .animation(reduceMotion ? nil : Motion.press, value: configuration.isPressed)
        }
    }
}
