//
//  MaskMath.swift
//  ConceptSegmenter
//
//  Created by David Sherlock on 2026.
//
//
//  The pure work around the model: checking a concept, turning the runtime's
//  boolean masks into bytes, the box origin, and the union of matches.
//

import CoreGraphics
import Foundation

enum MaskMath {

    /// The longest concept worth sending: SAM 3's text encoder reads 32
    /// tokens in the lite build and 77 in the full one; a phrase, not prose.
    static let maximumConceptLength = 120

    /// A concept as sent: trimmed, and refused when empty or too long.
    static func concept(_ text: String) throws(ConceptSegmenterError) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw .invalidConcept("say what to find — a word or a short phrase") }
        guard trimmed.count <= maximumConceptLength else {
            throw .invalidConcept("a concept is a short phrase, at most \(maximumConceptLength) characters")
        }
        return trimmed
    }

    /// The runtime's booleans as bytes.
    static func pixels(_ mask: [Bool]) -> [UInt8] {
        mask.map { $0 ? 255 : 0 }
    }

    /// A box from the runtime with its origin moved to the top-left.
    /// `bottomLeft` is how Apple's runtime reports it on macOS.
    static func topLeft(_ box: CGRect, imageHeight: Int, bottomLeft: Bool) -> CGRect {
        guard bottomLeft else { return box }
        return CGRect(x: box.minX, y: CGFloat(imageHeight) - box.maxY, width: box.width, height: box.height)
    }

    /// Every match's pixels in one mask; `nil` when there are none.
    static func union(_ masks: [ConceptMask]) -> ConceptMask? {
        guard let first = masks.first else { return nil }
        var pixels = first.pixels
        for mask in masks.dropFirst() where mask.width == first.width && mask.height == first.height {
            for i in 0..<pixels.count where mask.pixels[i] > pixels[i] { pixels[i] = mask.pixels[i] }
        }
        return ConceptMask(width: first.width, height: first.height, pixels: pixels)
    }

    /// The share of the image inside a mask, 0…1.
    static func coverage(_ mask: ConceptMask) -> Double {
        guard !mask.pixels.isEmpty else { return 0 }
        let inside: Int = mask.pixels.reduce(0) { $1 > 127 ? $0 + 1 : $0 }
        return Double(inside) / Double(mask.pixels.count)
    }
}
