import UIKit
import ImageIO

extension UIImage {
    /// Returns a resized copy if the image exceeds `maxDimension` on either axis.
    /// Uses ImageIO for memory-efficient downsampling (avoids decoding the full bitmap).
    func downsampledIfNeeded(maxDimension: CGFloat = 2048) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Load a thumbnail from a file path using ImageIO (never decodes the full bitmap into memory).
    /// `maxPixelSize` is the maximum dimension (width or height) for the resulting thumbnail.
    static func thumbnail(atPath path: String, maxPixelSize: CGFloat) -> UIImage? {
        let url = URL(fileURLWithPath: path)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize * UIScreen.main.scale,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
