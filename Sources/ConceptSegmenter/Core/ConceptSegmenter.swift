//
//  ConceptSegmenter.swift
//  ConceptSegmenter
//
//  Created by David Sherlock on 2026.
//
//  Masks by name: a word or short phrase in, every instance of it out, on
//  this device. SAM 3 (Meta) through Apple's own Core AI recipe and runtime
//  (apple/coreai-models), which does the resizing, tokenizing and decoding;
//  this file adds the measured score floor, a top-left box on every
//  platform, and the union. Measured on an M3 Max (full build): 11.6 s first
//  load, 0.84 s per prompt, 1.1 GB peak; IoU 0.986–0.993 on ten known-mask
//  composites, where SAM 2.1 Tiny clicked at the centre scored 0.58–0.99.
//

import CoreAIImageSegmenter
import CoreGraphics
import Foundation

/// Finds things by name.
///
/// ```swift
/// let segmenter = try await ConceptSegmenter(bundle: folder)
/// let dogs = try await segmenter.find("dog", in: image)
/// let sky = try await segmenter.mask(of: "sky", in: image)   // all matches, one mask
/// ```
///
/// Load it once and reuse it: the first load compiles the model for this
/// machine (about 12 s on an M3 Max, cached by the OS after that); each
/// prompt then costs under a second. Run one at a time — Core AI jobs on the
/// GPU do not share well.
public final class ConceptSegmenter: Sendable {

    /// The score below which a match is dropped. Measured on the stock and
    /// composite photos: every true match scored ≥ 0.84 and the worst false
    /// one 0.571 (an eagle's nostril for "eye"); Meta's own default, 0.5,
    /// lets that one in.
    public static let defaultMinimumScore: Float = 0.6

    private let handle: SegmenterHandle

    /// Loads a model bundle: a folder holding `metadata.json`, the
    /// `.aimodel` and the CLIP `tokenizer/`.
    public init(bundle: URL) async throws(ConceptSegmenterError) {
        guard FileManager.default.fileExists(atPath: bundle.appendingPathComponent("metadata.json").path) else {
            throw .modelUnavailable("no metadata.json in \(bundle.path)")
        }
        var parameters = SegmentationParameters.default
        parameters.maxSegments = 20
        do {
            handle = SegmenterHandle(
                segmenter: try await ImageSegmenter(resourcesAt: bundle.path, parameters: parameters),
                parameters: parameters)
        } catch is CancellationError {
            throw .cancelled
        } catch {
            throw .modelUnavailable("\(bundle.lastPathComponent): \(error.localizedDescription)")
        }
    }

    /// Every instance of `concept`, best first.
    ///
    /// - Parameters:
    ///   - concept: A noun or short noun phrase: "dog", "the red car", "sky".
    ///   - minimumScore: Matches below this are dropped (0…1).
    ///   - limit: The most to return.
    /// - Returns: Matches at the image's size; empty when there is none.
    public func find(_ concept: String, in image: CGImage,
                     minimumScore: Float = ConceptSegmenter.defaultMinimumScore,
                     limit: Int = 20) async throws(ConceptSegmenterError) -> [ConceptMatch] {
        let phrase = try MaskMath.concept(concept)
        let response: SegmentationResponse
        do {
            response = try await handle.segmenter.segment(image: image, prompt: phrase, parameters: handle.parameters)
        } catch is CancellationError {
            throw .cancelled
        } catch {
            throw .inference(error.localizedDescription)
        }
        #if os(macOS)
        let bottomLeft = true
        #else
        let bottomLeft = false
        #endif
        return response.segments
            .filter { $0.score >= minimumScore }
            .prefix(max(0, limit))
            .map { segment in
                ConceptMatch(
                    score: segment.score,
                    box: MaskMath.topLeft(segment.box, imageHeight: image.height, bottomLeft: bottomLeft),
                    mask: ConceptMask(width: segment.maskWidth, height: segment.maskHeight,
                                      pixels: MaskMath.pixels(segment.mask)))
            }
    }

    /// Every instance of `concept` in one mask, or `nil` when there is none.
    public func mask(of concept: String, in image: CGImage,
                     minimumScore: Float = ConceptSegmenter.defaultMinimumScore) async throws(ConceptSegmenterError) -> ConceptMask? {
        MaskMath.union(try await find(concept, in: image, minimumScore: minimumScore).map(\.mask))
    }
}

/// Apple's segmenter, carried across concurrency domains.
///
/// `ImageSegmenter` is not declared `Sendable`, but everything it stores is
/// immutable and Sendable: `let` properties holding Core AI
/// `InferenceFunction`s and their descriptors (both `Sendable` in the SDK),
/// input and output names, and a `Sendable` `CLIPTokenizer`. Checked against
/// coreai-models 1.0.0; the wrapper is the only unchecked type here.
struct SegmenterHandle: @unchecked Sendable {
    let segmenter: ImageSegmenter
    let parameters: SegmentationParameters
}
