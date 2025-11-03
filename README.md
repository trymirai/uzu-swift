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

## Quick Start

Add the `uzu` dependency to your project:

```swift
dependencies: [
    .package(url: "https://github.com/trymirai/uzu-swift.git", from: "0.1.40")
]
```

Set up your project through [Platform](https://platform.trymirai.com) and obtain an `API_KEY`. Then, choose the model you want from the [library](https://platform.trymirai.com/models) and run it with the following snippet using the corresponding identifier:

```swift
let engine = try await UzuEngine.create(apiKey: "API_KEY")

let model = try await engine.chatModel(repoId: "Qwen/Qwen3-0.6B")
try await engine.downloadChatModel(model) { update in
    print("Progress: \(update.progress)")
}

let session = try engine.chatSession(model)
let output = try session.run(
    input: .text(text: "Tell me a short, funny story about a robot"),
    config: RunConfig()
) { _ in
    return true
}
```

Everything from model downloading to inference configuration is handled automatically. Refer to the [documentation](https://docs.trymirai.com) for details on how to customize each step of the process.

## Examples

Place the `API_KEY` you obtained earlier in the corresponding example file, and then run it using one of the following commands:

```bash
swift run example chat
swift run example summarization
swift run example classification
```

### Chat

In this example, we will download a model and get a reply to a specific list of messages:

```swift
import Foundation
import Uzu

public func runChat() async throws {
    let engine = try await UzuEngine.create(apiKey: "API_KEY")

    let model = try await engine.chatModel(repoId: "Qwen/Qwen3-0.6B")
    try await engine.downloadChatModel(model) { update in
        print("Progress: \(update.progress)")
    }

    let messages = [
        Message(role: .system, content: "You are a helpful assistant."),
        Message(role: .user, content: "Tell me a short, funny story about a robot."),
    ]
    let input: Input = .messages(messages: messages)

    let session = try engine.chatSession(model)
    let runConfig = RunConfig()
        .tokensLimit(1024)
    let output = try session.run(
        input: input,
        config: runConfig
    ) { _ in
        return true
    }
    
    print(output.text.original)
}
```

Once loaded, the same `ChatSession` can be reused for multiple requests until you drop it. Each model may consume a significant amount of RAM, so it's important to keep only one session loaded at a time. For iOS apps, we recommend adding the [Increased Memory Capability](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.kernel.increased-memory-limit) entitlement to ensure your app can allocate the required memory.

### Summarization

In this example, we will use the `summarization` preset to generate a summary of the input text:

```swift
import Foundation
import Uzu

public func runSummarization() async throws {
    let engine = try await UzuEngine.create(apiKey: "API_KEY")

    let model = try await engine.chatModel(repoId: "Qwen/Qwen3-0.6B")
    try await engine.downloadChatModel(model) { update in
        print("Progress: \(update.progress)")
    }

    let textToSummarize =
        "A Large Language Model (LLM) is a type of AI that processes and generates text using transformer-based architectures trained on vast datasets. They power chatbots, translation, code assistants, and more."
    let input: Input = .text(
        text: "Text is: \"\(textToSummarize)\". Write only summary itself.")

    let session = try engine.chatSession(model, config: Config(preset: .summarization))
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

    print("Summary: \(output.text.original)")
    print(
        "Model runs: \(output.stats.prefillStats.modelRun.count + (output.stats.generateStats?.modelRun.count ?? 0))"
    )
    print("Tokens count: \(output.stats.totalStats.tokensCountOutput)")
}
```

You will notice that the model’s run count is lower than the actual number of generated tokens due to speculative decoding, which significantly improves generation speed.

### Classification

In this example, we will use the `classification` preset to determine the sentiment of the user's input:

```swift
import Foundation
import Uzu

public func runClassification() async throws {
    let engine = try await UzuEngine.create(apiKey: "API_KEY")

    let model = try await engine.chatModel(repoId: "Qwen/Qwen3-0.6B")
    try await engine.downloadChatModel(model) { update in
        print("Progress: \(update.progress)")
    }

    let feature = ClassificationFeature(
        name: "sentiment",
        values: ["Happy", "Sad", "Angry", "Fearful", "Surprised", "Disgusted"]
    )
    let textToDetectFeature =
        "Today's been awesome! Everything just feels right, and I can't stop smiling."
    let prompt =
        "Text is: \"\(textToDetectFeature)\". Choose \(feature.name) from the list: \(feature.values.joined(separator: ", ")). Answer with one word. Don't add a dot at the end."
    let input: Input = .text(text: prompt)

    let config = Config(preset: .classification(feature: feature))
    let session = try engine.chatSession(model, config: config)
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
    
    print("Prediction: \(output.text.original)")
    print("Stats: \(output.stats)")
}
```

You can view the stats to see that the answer will be ready immediately after the prefill step, and actual generation won’t even start due to speculative decoding, which significantly improves generation speed.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
