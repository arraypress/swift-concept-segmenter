//
//  MaskMathTests.swift
//  ConceptSegmenterTests
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics
import Testing
@testable import ConceptSegmenter

@Suite("Mask math")
struct MaskMathTests {

    @Test("A concept is trimmed, and refused when empty or prose-long")
    func concepts() throws {
        #expect(try MaskMath.concept("  the red car \n") == "the red car")
        #expect(throws: ConceptSegmenterError.self) { try MaskMath.concept("   ") }
        #expect(throws: ConceptSegmenterError.self) { try MaskMath.concept(String(repeating: "dog ", count: 40)) }
    }

    @Test("A bottom-left box comes back top-left; a top-left one is untouched")
    func boxOrigin() {
        let box = CGRect(x: 10, y: 20, width: 30, height: 40)
        #expect(MaskMath.topLeft(box, imageHeight: 100, bottomLeft: true) == CGRect(x: 10, y: 40, width: 30, height: 40))
        #expect(MaskMath.topLeft(box, imageHeight: 100, bottomLeft: false) == box)
    }

    @Test("The union keeps every match's pixels; coverage counts them")
    func unionAndCoverage() {
        let a = ConceptMask(width: 2, height: 2, pixels: [255, 0, 0, 0])
        let b = ConceptMask(width: 2, height: 2, pixels: [0, 0, 0, 255])
        let both = ConceptMask.union([a, b])
        #expect(both?.pixels == [255, 0, 0, 255])
        #expect(both?.coverage == 0.5)
        #expect(ConceptMask.union([]) == nil)
        #expect(MaskMath.pixels([true, false]) == [255, 0])
    }

    @Test("A mask becomes a grayscale image of its own size")
    func image() {
        let mask = ConceptMask(width: 3, height: 2, pixels: [0, 255, 0, 255, 0, 255])
        let image = mask.cgImage
        #expect(image?.width == 3 && image?.height == 2)
        #expect(ConceptMask(width: 3, height: 2, pixels: [0]).cgImage == nil, "wrong pixel count")
    }
}
