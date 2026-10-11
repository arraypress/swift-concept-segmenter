//
//  ConceptModel.swift
//  ConceptSegmenter
//
//  Created by David Sherlock on 2026.
//

/// The SAM 3 build this library is measured against: Apple's coreai-models
/// recipe, `--full --dtype float16` (1008 px), hosted for download.
///
/// Apple's iOS "lite" export (336 px, palettized) was measured too and is
/// not offered: 0.2 s per prompt and 383 MB, but on ten known-mask
/// composites its scores spread from 0.07 to 0.93 (one animal missed
/// outright) and IoU fell to 0.75–0.97, against 0.986–0.993 here.
public enum ConceptModel {

    /// The Hugging Face repository holding the bundle.
    public static let repository = "arraypress/segment-sam3"

    /// The bundle folder in ``repository``: `metadata.json`, the `.aimodel`
    /// and the CLIP `tokenizer/`.
    public static let bundleName = "sam3-float16"

    /// Meta's licence, which travels with the weights.
    public static let licence = "SAM License (Meta)"
}
