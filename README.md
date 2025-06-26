# Uzu Swift – Local AI on Apple Silicon

[![Platform Compatibility](https://img.shields.io/badge/Platforms-iOS-brightgreen)](https://swift.org/platforms/)
[![Swift Version](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org)

A Swift package that lets you run **Mirai's** Metal-accelerated LLMs entirely on-device.

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/getmirai/uzu-swift.git", from: "0.1.0")
]
```

## Usage

### Bootstrapping the engine

```swift
import Uzu

let engine = UzuEngine(apiKey: "<#YOUR_MIRAI_API_KEY#>")
```

Visit [https://platform.trymirai.com/](https://platform.trymirai.com/) to get your API key.
*It is required to activate your license and use the engine.*

### Refresh the remote registry (optional)

```swift
let registry = try await engine.updateRegistry() // fetches the latest list & states
let modelIds = registry.map(\.key)
```

### Downloading / managing models

```swift
// start downloading a model by its identifier
engine.download(identifier: "Llama-3.2-3B-Instruct-FP16")

// you can also pause / resume / delete
engine.pause(identifier: id)
engine.resume(identifier: id)
engine.delete(identifier: id)
```

### Observing download progress

`UzuEngine` conforms to `@Observable` and updates the `states` dictionary in real-time.

```swift
@Environment(UzuEngine.self) private var engine

ProgressView(value: engine.states[id]?.progress ?? 0)
    .tint(.accentColor)
```

Possible `ModelState` cases:

* `.notDownloaded`
* `.downloading(progress: Double)`
* `.paused(progress: Double)`
* `.downloaded`
* `.error(message: String)`

### Opening a session

Sessions are inference objects created per model.

```swift
let session = try engine.createSession(identifier: "Llama-3.2-3B-Instruct-FP16")
```

Next, **load** the session with a `SessionConfig` that defines a *preset*, sampling seed and desired context length.

```swift
let config = SessionConfig(
    preset: .general,               // see variants below
    samplingSeed: .default,
    contextLength: .default
)
try session.load(config: config)
```

Once loaded, the same session can be reused for many requests until you drop it.
Each model can consume up to 4 GB or ram, so it is important one loaded session at a time.

### Streaming inference

`Session.run` returns progressively generated output through a *progress closure* and finally the full `SessionOutput`.

```swift
let final = session.run(
    input: .text("Hello Uzu 👋"),
    maxTokens: 128,
    samplingMethod: .argmax
) { partial in
    print(partial.text)   // every new chunk
    return true           // return false to cancel generation
}
print("Finished:", final.text)
```

### Presets in action

`SessionPreset` lets the same model behave very differently. Below are the three presets showcased in the playground.

#### General chat

```swift
let chatConfig = SessionConfig(
    preset: .general,
    samplingSeed: .default,
    contextLength: .default
)
try session.load(config: chatConfig)
```

#### Classification

```swift
let feature = SessionClassificationFeature(
    name: "sentiment",
    values: ["negative", "neutral", "positive"]
)
let classificationConfig = SessionConfig(
    preset: .classification(feature),
    samplingSeed: .default,
    contextLength: .default
)
try session.load(config: classificationConfig)
```

After running `session.run(input:.text("I love this phone"), maxTokens:1,… )` the model will reply with one of the provided labels.

#### Summarisation

```swift
let summarizationConfig = SessionConfig(
    preset: .summarization,
    samplingSeed: .default,
    contextLength: .default
)
try session.load(config: sumCfg)
```

## Playground

Open the **Playground** target in Xcode—each SwiftUI view (e.g. `ChatView.swift`, `ClassificationView.swift`) contains production-ready snippets you can lift straight into your app.

## License

This project is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
