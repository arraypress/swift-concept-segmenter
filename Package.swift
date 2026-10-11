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
        // pre- and post-processing, kept working by Apple across OS betas.
        .package(url: "https://github.com/apple/coreai-models.git", from: "1.0.0"),
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
