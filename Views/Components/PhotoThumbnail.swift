import SwiftUI

/// A square check-in photo with small rounded corners. Shows a placeholder when there's no image
/// (always, for now: real photos arrive with the camera phase).
struct PhotoThumbnail: View {
    var image: Image?

    var body: some View {
        Color.app.surfaceMuted
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .font(Font.app.cardTitle)
                        .foregroundStyle(Color.app.textTertiary)
                }
            }
            .clipShape(.rounded(Radius.sm))
            .accessibilityLabel(Strings.Accessibility.photo)
    }
}
