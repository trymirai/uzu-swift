<p align="center">
  <picture>
    <img alt="Mirai" src="https://artifacts.trymirai.com/social/github/uzu-swift-header.jpg" style="max-width: 100%;">
  </picture>
</p>

<a href="https://artifacts.trymirai.com/social/about_us.mp3"><img src="https://img.shields.io/badge/Listen-Podcast-red" alt="Listen to our podcast"></a>
<a href="https://docsend.com/v/76bpr/mirai2025"><img src="https://img.shields.io/badge/View-Deck-red" alt="View our deck"></a>
<a href="mailto:alexey@getmirai.co,dima@getmirai.co,aleksei@getmirai.co?subject=Interested%20in%20Mirai"><img src="https://img.shields.io/badge/Send-Email-green" alt="Contact us"></a>
<a href="https://docs.trymirai.com/app-integration/overview"><img src="https://img.shields.io/badge/Read-Docs-blue" alt="Read docs"></a>
[![Swift Version](https://img.shields.io/badge/Swift-5.9-blue)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)

# uzu-swift

Swift package for [uzu](https://github.com/trymirai/uzu), a **high-performance** inference engine for AI models on Apple Silicon. It allows you to deploy AI directly in your app with **zero latency**, **full data privacy**, and **no inference costs**. You don’t need an ML team or weeks of setup - one developer can handle everything in minutes. Key features:

- Simple, high-level API
- Specialized configurations with significant performance boosts for common use cases like classification and summarization
- [Broad model support](https://trymirai.com/models)
- Observable model manager

## Examples

Set up your project through [Platform](https://platform.trymirai.com) and obtain an `API_KEY`. Place the `API_KEY` in the corresponding example file, and then run it using one of the following commands:

```shell
swift run example chat
swift run example summarization
swift run example classification
```

### Setup

Add the `uzu-swift` dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/trymirai/uzu-swift.git", from: "0.1.28")
]
```

Create and activate engine:

```swift
let engine = UzuEngine()
let status = try await engine.activate(apiKey: "API_KEY")
```

### Choose model

```swift
let repoId = "Qwen/Qwen3-0.6B"
```

### Download with progress handle

```swift
let modelDownloadState = engine.downloadState(repoId: repoId)
if modelDownloadState?.phase != .downloaded {
    let handle = try engine.downloadHandle(repoId: repoId)
    try await handle.download()
    let progressStream = handle.progress()
    while let progressUpdate = await progressStream.next() {
        print("Progress: \(progressUpdate.progress)")
    }
}
```

### Session

`Session` is the core entity used to communicate with the model:

```swift
let session = try engine.createSession(
    repoId,
    modelType: .local,
    config: Config(preset: .general)
)
```

Once loaded, the same `Session` can be reused for multiple requests until you drop it. Each model may consume a significant amount of RAM, so it's important to keep only one session loaded at a time. For iOS apps, we recommend adding the [Increased Memory Capability](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.kernel.increased-memory-limit) entitlement to ensure your app can allocate the required memory.

### Chat

After creating it, you can run the `Session` with a specific prompt or a list of messages:

```swift
let messages = [
    Message(role: .system, content: "You are a helpful assistant."),
    Message(role: .user, content: "Tell me a short, funny story about a robot."),
]
let input: Input = .messages(messages: messages)
```

```swift
let runConfig = RunConfig()
    .tokensLimit(1024)

let output = try session.run(
    input: input,
    config: runConfig
) { _ in
    return true
}
```

`Output` also includes generation metrics such as prefill duration and tokens per second. It’s important to note that you should run a **release** build to obtain accurate metrics.

### Summarization

In this example, we will extract a summary of the input text:

```swift
let session = try engine.createSession(
    repoId,
    modelType: .local,
    config: Config(preset: .summarization)
)
```

```swift
let textToSummarize =
    "A Large Language Model (LLM) is a type of AI that processes and generates text using transformer-based architectures trained on vast datasets. They power chatbots, translation, code assistants, and more."
let input: Input = .text(
    text: "Text is: \"\(textToSummarize)\". Write only summary itself.")
```

```swift
let runConfig = RunConfig()
    .tokensLimit(256)
    .enableThinking(false)
    .samplingPolicy(.custom(value: .greedy))

let output = try session.run(
    input: input,
    config: runConfig
) { _ in
    return true
}
```

This will generate ~34 output tokens with only ~5 model runs during the generation phase, instead of ~34 runs.

### Classification

Let’s look at a case where you need to classify input text based on a specific feature, such as `sentiment`:

```swift
let feature = ClassificationFeature(
    name: "sentiment",
    values: ["Happy", "Sad", "Angry", "Fearful", "Surprised", "Disgusted"]
)
let config = Config(preset: .classification(feature: feature))

let session = try engine.createSession(repoId, modelType: .local, config: config)
```

```swift
let textToDetectFeature =
    "Today's been awesome! Everything just feels right, and I can't stop smiling."
let prompt =
    "Text is: \"\(textToDetectFeature)\". Choose \(feature.name) from the list: \(feature.values.joined(separator: ", ")). Answer with one word. Don't add a dot at the end."
let input: Input = .text(text: prompt)
```

```swift
let runConfig = RunConfig()
    .tokensLimit(32)
    .enableThinking(false)
    .samplingPolicy(.custom(value: .greedy))

let output = try session.run(
    input: input,
    config: runConfig
) { _ in
    return true
}
```

In this example, you will get the answer `Happy` immediately after the prefill step, and the actual generation won't even start.

## License

This project is licensed under the MIT License. See the LICENSE file for details.