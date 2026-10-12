// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ConceptSegmenter",
    platforms: [
        // Core AI: the runtime SAM 3 runs on.
        .macOS("27.0"), .iOS("27.0"),
    ],
    products: [
        .library(name: "ConceptSegmenter", targets: ["ConceptSegmenter"]),
    ],
    dependencies: [
        // Apple's official Core AI recipes and runtime (BSD-3): SAM 3's
        // pre- and post-processing, kept working by Apple across OS betas —
        // through arraypress's fork of it: Apple's 1.0.0 plus a diffusion-only
        // change (non-square exports). Segmentation is Apple's code unchanged; the
        // fork is used so this package can sit beside swift-image-generation in
        // one tool (`imagine --only`) — SwiftPM cannot hold two packages called
        // coreai-models from different URLs. Alone, this resolves to the fork's 1.0.0.
        .package(url: "https://github.com/arraypress/coreai-models.git", from: "1.0.0-nonsquare.1"),
    ],
    targets: [
        .target(
            name: "ConceptSegmenter",
            dependencies: [.product(name: "CoreAISegmentation", package: "coreai-models")]),
        .testTarget(name: "ConceptSegmenterTests", dependencies: ["ConceptSegmenter"]),
    ]
)

// Swift 7's import rule, today: a file must import every module whose members
// it uses, rather than leaning on another file's imports.
for target in package.targets where target.type != .system && target.type != .binary && target.type != .plugin {
    target.swiftSettings = (target.swiftSettings ?? []) + [.enableUpcomingFeature("MemberImportVisibility")]
}
