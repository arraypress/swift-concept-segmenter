# swift-concept-segmenter

Masks by name, on this device. Give it an image and a word or short phrase — `dog`, `eye`,
`the red car`, `sky` — and it returns every instance: a mask at the image's size, a box and a
score. Meta's **SAM 3** on Apple's Core AI runtime, through Apple's own recipe and Swift
package ([apple/coreai-models](https://github.com/apple/coreai-models)), resolved through [arraypress's fork](https://github.com/arraypress/coreai-models) of it — Apple's 1.0.0 plus a diffusion-only change — so this library and swift-image-generation can share one tool (SwiftPM cannot hold two packages named coreai-models from different URLs). Segmentation is Apple's code, unchanged.

```swift
import ConceptSegmenter

let segmenter = try await ConceptSegmenter(bundle: folder)   // a downloaded sam3-float16/ bundle
let eyes = try await segmenter.find("eye", in: image)          // [ConceptMatch], best first
let sky = try await segmenter.mask(of: "sky", in: image)       // every match in one mask, or nil
```

- 🔤 **Open vocabulary** — any noun phrase, no fixed class list; two of a kind come back as two
  instances (an owl's eyes: 0.955 and 0.951).
- 🎯 **A measured score floor** — `defaultMinimumScore` is 0.6: on the five stock animal
  photos macOS ships, every true match scored ≥ 0.84 and the worst false one 0.571 (an eagle's
  nostril for "eye"). Meta's default, 0.5, lets that one in. Absent concepts return `[]`.
- 📐 **One coordinate system** — boxes are top-left origin on every platform; Apple's runtime
  reports them bottom-left on macOS and top-left on iOS.
- 🧵 **Sendable** — load once, reuse from anywhere; typed throws (`ConceptSegmenterError`).
- 📱 **macOS 27 / iOS 27** — Core AI's floor.

## The model

Hosted at [arraypress/segment-sam3](https://huggingface.co/arraypress/segment-sam3)
(`ConceptModel.repository` / `.bundleName`), exported with Apple's recipe at coreai-models
`52dbd93`: `--full --dtype float16`, 1008 px, 1.6 GB, under Meta's **SAM License** (a copy
ships with the weights). This library does not download; the tools built on it fetch the
bundle on first use.

## Measured (macOS 27, M3 Max, 36 GB)

| Measure | Result |
|---|---|
| first load (compiles for this machine; the OS caches it) | 11.6 s |
| one prompt, warm | 0.84 s |
| peak memory | 1.1 GB |
| IoU, ten known-mask composites (five animals × plain / busy background) | 0.986–0.993 |
| SAM 2.1 Tiny clicked at each object's centre, same composites | 0.58–0.99 |

Apple's iOS "lite" export (336 px, palettized) is not offered: 0.2 s and 383 MB, but its
scores spread from 0.07 to 0.93 on the same composites — one animal missed outright — and IoU
fell to 0.75–0.97. It needs measuring on an iPhone before an app should use it.

Masks are hard-edged (Apple's runtime thresholds the logits at full resolution); feather them
in the host when compositing.

## Tests

`swift test` runs the pure parts. With `CONCEPT_SEGMENTER_BUNDLE=/path/to/sam3-float16` it also
runs the model on the stock `Parrot.heic`: the parrot is found (> 0.9), "sky" is not, and the
eye's box agrees with its own mask's pixels — which pins the top-left origin.

## Requirements

macOS 27 / iOS 27, Swift 6.2; building needs the 27 SDKs (Core AI). On iOS it runs on
devices only: the iOS 27 **Simulator** SDK has no Core AI framework, so a Simulator build of
anything using it fails inside Apple's package — check iOS with a device build
(`-destination 'generic/platform=iOS'`).

## License

MIT for this library — see LICENSE. The model weights are Meta's, under the SAM License.
