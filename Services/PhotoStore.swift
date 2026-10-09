import UIKit

/// Check-in photos on the iPhone (context.md §11): JPEGs (longest side 1600 px, quality 0.7) with unique names,
/// in the app's private Application Support/Photos folder. Never the camera roll.
final class PhotoStore {
    static let shared = PhotoStore()

    static let maxSide: CGFloat = 1600
    static let quality: CGFloat = 0.7

    let folder: URL
    private let thumbnails = NSCache<NSString, UIImage>()

    /// `folder` is replaceable so tests can use a temporary one.
    init(folder: URL? = nil) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.folder = folder ?? base.appendingPathComponent("Photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: self.folder, withIntermediateDirectories: true)
    }

    /// Resizes, compresses, and saves a photo. Returns its file name.
    func save(_ image: UIImage) throws -> String {
        guard let data = Self.jpeg(image) else { throw CocoaError(.fileWriteUnknown) }
        let name = UUID().uuidString + ".jpg"
        try data.write(to: url(name), options: [.atomic, .completeFileProtection])
        return name
    }

    /// The photo, scaled so its longest side is at most 1600 px, as a quality-0.7 JPEG.
    static func jpeg(_ image: UIImage) -> Data? {
        let longest = max(image.size.width, image.size.height)
        let scale = longest > maxSide ? maxSide / longest : 1
        let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: quality)
    }

    func url(_ fileName: String) -> URL { folder.appendingPathComponent(fileName) }

    func image(_ fileName: String) -> UIImage? {
        UIImage(contentsOfFile: url(fileName).path)
    }

    /// A small copy for grids, cached in memory.
    func thumbnail(_ fileName: String, side: CGFloat = 300) -> UIImage? {
        if let cached = thumbnails.object(forKey: fileName as NSString) { return cached }
        guard let image = image(fileName) else { return nil }
        let thumbnail = image.preparingThumbnail(of: CGSize(width: side, height: side * image.size.height
            / max(image.size.width, 1))) ?? image
        thumbnails.setObject(thumbnail, forKey: fileName as NSString)
        return thumbnail
    }

    func delete(_ fileNames: [String]) {
        for name in fileNames {
            try? FileManager.default.removeItem(at: url(name))
            thumbnails.removeObject(forKey: name as NSString)
        }
    }

    /// Deletes every photo (Delete all data).
    func deleteAll() {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        delete(files)
    }

    /// How many photo files there are and how many bytes they take.
    func usage() -> (count: Int, bytes: Int64) {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.fileSizeKey]))
            ?? []
        let bytes = files.reduce(Int64(0)) { total, url in
            total + Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return (files.count, bytes)
    }
}
