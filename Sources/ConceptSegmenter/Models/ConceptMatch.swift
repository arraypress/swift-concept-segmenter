//
//  ConceptMatch.swift
//  ConceptSegmenter
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics

/// One instance of a concept in an image.
public struct ConceptMatch: Sendable, Equatable {

    /// How sure the model is, 0…1: SAM 3's detection score times its
    /// presence score.
    public let score: Float

    /// The instance's bounds in pixels, origin top-left on every platform.
    /// (Apple's runtime reports it bottom-left on macOS and top-left on iOS.)
    public let box: CGRect

    /// The instance's pixels.
    public let mask: ConceptMask

    public init(score: Float, box: CGRect, mask: ConceptMask) {
        self.score = score
        self.box = box
        self.mask = mask
    }
}
