import ImageIO
import UIKit

enum ImageService {
    enum ImageError: LocalizedError {
        case unreadable
        var errorDescription: String? { "This photo could not be loaded. Please choose another image." }
    }

    /// Decode a thumbnail directly so a large library image does not expand at full resolution.
    static func prepare(_ data: Data) throws -> Data {
        guard data.count <= 40 * 1024 * 1024,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1600,
                kCGImageSourceShouldCacheImmediately: true,
              ] as CFDictionary),
              let jpeg = UIImage(cgImage: thumbnail).jpegData(compressionQuality: 0.8)
        else { throw ImageError.unreadable }
        return jpeg
    }
}
