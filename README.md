<p align="center">
  <picture>
    <img alt="Mirai" src="https://artifacts.trymirai.com/social/github/header.jpg" style="max-width: 100%;">
  </picture>
</p>

<a href="https://notebooklm.google.com/notebook/5851ef05-463e-4d30-bd9b-01f7668e8f8f/audio"><img src="https://img.shields.io/badge/Listen-Podcast-red" alt="Listen to our podcast"></a>
<a href="https://docsend.com/view/x87pcxrnqutb9k2q"><img src="https://img.shields.io/badge/View-Deck-red" alt="View our deck"></a>
<a href="mailto:alexey@getmirai.co,dima@getmirai.co,aleksei@getmirai.co?subject=Interested%20in%20Mirai"><img src="https://img.shields.io/badge/Send-Email-green" alt="Contact us"></a>
<a href="https://docs.trymirai.com/components/inference-engine"><img src="https://img.shields.io/badge/Read-Docs-blue" alt="Read docs"></a>
[![Swift Version](https://img.shields.io/badge/Swift-5.9-blue)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)

# uzu-swift

Swift package for [uzu](https://github.com/trymirai/uzu), a **high-performance** inference engine for AI models on Apple Silicon. It allows you to deploy AI directly in your app with **zero latency**, **full data privacy**, and **no inference costs**. You don’t need an ML team or weeks of setup - one developer can handle everything in minutes. Key features:

- Simple, high-level API
- Specialized configurations with significant performance boosts for common use cases like classification and summarization
- [Broad model support](https://trymirai.com/models)
- Observable model manager

## Quick Start

### Setup

Add the `uzu-swift` dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/trymirai/uzu-swift.git", from: "0.1.1")
]
```

Set up your project via [Platform](https://platform.trymirai.com), obtain an `API_KEY`, and initialize engine:

```swift
import Uzu

let engine = UzuEngine(apiKey: "API_KEY")
```

### Refresh models registry:

```swift
let registry = try await engine.updateRegistry()
let modelIdentifiers = registry.map(\.key)
```

### Download with progress handle

```swift
let modelIdentifier = "Meta-Llama-3.2-1B-Instruct-float16"

let handle = try engine.downloadHandle(identifier: modelIdentifier)
try handle.startDownload()

for try await progress in handle.progress {
    print("Progress: \(Int(progress * 100))%")
}
```

Alternatively, you may use engine to control and observe model download:

```swift
engine.download(identifier: modelIdentifier)
engine.pause(identifier: modelIdentifier)
engine.resume(identifier: modelIdentifier)
engine.delete(identifier: modelIdentifier)
...

ProgressView(value: engine.states[id]?.progress ?? 0.0)
```

Possible model state values:

- `.notDownloaded`
- `.downloading(progress: Double)`
- `.paused(progress: Double)`
- `.downloaded`
- `.error(message: String)`

### Session

`Session` is the core entity used to communicate with the model:

```swift
let session = try engine.createSession(identifier: modelIdentifier)
```

`Session` offers different configuration presets that can provide significant performance boosts for common use cases like classification and summarization:

```swift
let config = SessionConfig(
    preset: .general,
    samplingSeed: .default,
    contextLength: .default
)
try session.load(config: config)
```

Once loaded, the same `Session` can be reused for multiple requests until you drop it. Each model may consume a significant amount of RAM, so it's important to keep only one session loaded at a time. For iOS apps, we recommend adding the [Increased Memory Capability](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.kernel.increased-memory-limit) entitlement to ensure your app can allocate the required memory.

### Inference

After loading, you can run the `Session` with a specific prompt or a list of messages:

```swift
let input = SessionInput.messages([
    .init(role: .system, content: "You are a helpful assistant"),
    .init(role: .user, content: "Tell about London")
])
let output = session.run(
    input: input,
    maxTokens: 128,
    samplingMethod: .argmax
) { partialOutput in
    // Access the current text using partialOutput.text
    return true // Return true to continue generation
}
```

`SessionOutput` also includes generation metrics such as prefill duration and tokens per second. It’s important to note that you should run a **release** build to obtain accurate metrics.

### Presets

#### Summarization

In this example, we will extract a summary of the input text:

```swift
let textToSummarize = "A Large Language Model (LLM) is a type of artificial intelligence that processes and generates human-like text. It is trained on vast datasets containing books, articles, and web content, allowing it to understand and predict language patterns. LLMs use deep learning, particularly transformer-based architectures, to analyze text, recognize context, and generate coherent responses. These models have a wide range of applications, including chatbots, content creation, translation, and code generation. One of the key strengths of LLMs is their ability to generate contextually relevant text based on prompts. They utilize self-attention mechanisms to weigh the importance of words within a sentence, improving accuracy and fluency. Examples of popular LLMs include OpenAI's GPT series, Google's BERT, and Meta's LLaMA. As these models grow in size and sophistication, they continue to enhance human-computer interactions, making AI-powered communication more natural and effective.";
let text = "Text is: \"\(textToSummarize)\". Write only summary itself."

let config = SessionConfig(
    preset: .summarization,
    samplingSeed: .default,
    contextLength: .default
)
try session.load(config: config)

let input = SessionInput.text(text)
let output = session.run(
    input: input,
    maxTokens: 1024,
    samplingMethod: .argmax
) { _ in
    return true
}
```

This will generate 34 output tokens with only 5 model runs during the generation phase, instead of 34 runs.

#### Classification

Let’s look at a case where you need to classify input text based on a specific feature, such as `sentiment`:

```swift
let feature = SessionClassificationFeature(
    name: "sentiment",
    values: ["Happy", "Sad", "Angry", "Fearful", "Surprised", "Disgusted"]
)

let textToDetectFeature = "Today's been awesome! Everything just feels right, and I can't stop smiling."
let text = "Text is: \"\(textToDetectFeature)\". Choose \(feature.name) from the list: \(feature.values.joined(separator: ", ")). Answer with one word. Dont't add dot at the end."

let config = SessionConfig(
    preset: .classification(feature),
    samplingSeed: .default,
    contextLength: .default
)
try session.load(config: config)

let input = SessionInput.text(text)
let output = session.run(
    input: input,
    maxTokens: 32,
    samplingMethod: .argmax
) { _ in
    return true
}
```

In this example, you will get the answer `Happy` immediately after the prefill step, and the actual generation won't even start.

## Playground

You can find the examples described above in the [Playground](Playground) app.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
