import SwiftUI

/// A square check-in photo with small rounded corners. Loads the saved photo by file name (sample data has
/// none, so it shows a placeholder).
struct PhotoThumbnail: View {
    var image: Image?
    /// A saved photo in `PhotoStore`.
    var fileName: String?

    @State private var loaded: UIImage?

    var body: some View {
        Color.app.surfaceMuted
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image = image ?? loaded.map(Image.init(uiImage:)) {
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
            .task(id: fileName) {
                guard let fileName else { return }
                loaded = await Task.detached(priority: .userInitiated) {
                    PhotoStore.shared.thumbnail(fileName)
                }.value
            }
    }
}
