//
//  LiveTests.swift
//  ConceptSegmenterTests
//
//  Created by David Sherlock on 2026.
//
//  The real model, on a photo every Mac ships, when CONCEPT_SEGMENTER_BUNDLE
//  points at a downloaded bundle (sam3-float16). Skipped otherwise.
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import ConceptSegmenter

private let liveBundle = ProcessInfo.processInfo.environment["CONCEPT_SEGMENTER_BUNDLE"]
private let stockParrot = URL(fileURLWithPath: "/System/Library/Templates/Data/Library/User Pictures/Animals/Parrot.heic")

@Suite("Live SAM 3", .serialized)
struct LiveTests {

    static func image(_ url: URL) throws -> CGImage {
        let source = try #require(CGImageSourceCreateWithURL(url as CFURL, nil))
        return try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
    }

    @Test("The parrot is found, the sky is not, and the box is top-left",
          .enabled(if: liveBundle != nil && FileManager.default.fileExists(atPath: stockParrot.path)))
    func parrot() async throws {
        let segmenter = try await ConceptSegmenter(bundle: URL(fileURLWithPath: liveBundle!))
        let image = try Self.image(stockParrot)

        let parrots = try await segmenter.find("parrot", in: image)
        let best = try #require(parrots.first)
        #expect(best.score > 0.9)
        #expect(best.mask.width == image.width && best.mask.height == image.height)
        #expect(best.mask.coverage > 0.4, "the parrot fills most of the frame")

        // The eye is in the upper half of the photo; a top-left box says so.
        let eye = try #require(try await segmenter.find("eye", in: image).first)
        #expect(eye.box.midY < CGFloat(image.height) / 2)
        // And the mask agrees with the box: the eye's pixels sit inside it.
        let rows = (0..<image.height).filter { y in (0..<image.width).contains { eye.mask.pixels[y * image.width + $0] > 0 } }
        #expect(abs(CGFloat(rows.first ?? 0) - eye.box.minY) <= 2)

        #expect(try await segmenter.find("sky", in: image).isEmpty, "no sky in a close-up")
        await #expect(throws: ConceptSegmenterError.self) { _ = try await segmenter.find(" ", in: image) }
    }
}
