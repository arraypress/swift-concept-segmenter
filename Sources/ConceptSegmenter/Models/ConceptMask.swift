//
//  ConceptMask.swift
//  ConceptSegmenter
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A mask at the image's own size: `255` inside, `0` outside, row-major from
/// the top-left pixel.
public struct ConceptMask: Sendable, Equatable {

    public let width: Int
    public let height: Int
    public let pixels: [UInt8]

    public init(width: Int, height: Int, pixels: [UInt8]) {
        self.width = width
        self.height = height
        self.pixels = pixels
    }
}
