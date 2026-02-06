import UIKit

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
}
