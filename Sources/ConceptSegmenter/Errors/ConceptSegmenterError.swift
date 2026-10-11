//
//  ConceptSegmenterError.swift
//  ConceptSegmenter
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What can go wrong finding a concept. Finding nothing is not an error:
/// ``ConceptSegmenter/find(_:in:minimumScore:limit:)`` returns no matches.
public enum ConceptSegmenterError: Error, LocalizedError, Sendable, Equatable {

    /// The model bundle is missing, incomplete or would not load.
    case modelUnavailable(String)

    /// The concept was empty, or too long to be one.
    case invalidConcept(String)

    /// The model ran and failed.
    case inference(String)

    /// The task was cancelled.
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .modelUnavailable(let why): "the segmentation model is unavailable: \(why)"
        case .invalidConcept(let why): why
        case .inference(let why): "segmentation failed: \(why)"
        case .cancelled: "segmentation was cancelled"
        }
    }
}
