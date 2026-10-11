//
//  ConceptMask+Image.swift
//  ConceptSegmenter
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics
import Foundation

public extension ConceptMask {

    /// The share of the image inside the mask, 0…1.
    var coverage: Double { MaskMath.coverage(self) }

    /// The mask as an 8-bit grayscale image, white inside.
    var cgImage: CGImage? {
        guard width > 0, height > 0, pixels.count == width * height,
              let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: width,
                       space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0),
                       provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }

    /// Every match's pixels in one mask; `nil` for none.
    static func union(_ masks: [ConceptMask]) -> ConceptMask? { MaskMath.union(masks) }
}
