<p align="center">
  <picture>
    <img alt="Mirai" src="https://artifacts.trymirai.com/social/github/uzu-swift-header.jpg" style="max-width: 100%;">
  </picture>
</p>

<a href="https://artifacts.trymirai.com/social/about_us.mp3"><img src="https://img.shields.io/badge/Listen-Podcast-red" alt="Listen to our podcast"></a>
<a href="https://docsend.com/v/76bpr/mirai2025"><img src="https://img.shields.io/badge/View-Deck-red" alt="View our deck"></a>
<a href="https://discord.com/invite/trymirai"><img src="https://img.shields.io/discord/1377764166764462120?label=Discord" alt="Discord"></a>
<a href="mailto:contact@getmirai.co?subject=Interested%20in%20Mirai"><img src="https://img.shields.io/badge/Send-Email-green" alt="Contact us"></a>
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
    .package(url: "https://github.com/trymirai/uzu-swift.git", from: "0.2.6")
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
swift run example chat-dynamic-context
swift run example chat-static-context
swift run example summarization
swift run example classification
swift run example cloud
swift run example structured-output
```

### Chat

In this example, we will download a model and get a reply to a specific list of messages:

```swift
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

### Chat with dynamic context

In this example, we will use the dynamic `ContextMode`, which automatically maintains a continuous conversation history instead of resetting the context with each new input. Every new message is added to the ongoing chat, allowing the model to remember what has already been said and respond with full context.

```swift
import Uzu

public func runChatDynamicContext() async throws {
    let engine = try await UzuEngine.create(apiKey: "API_KEY")

    let model = try await engine.chatModel(repoId: "Qwen/Qwen3-0.6B")
    try await engine.downloadChatModel(model) { update in
        print("Progress: \(update.progress)")
    }

    let config = Config(preset: .general)
        .contextMode(.dynamic)
    let session = try engine.chatSession(model, config: config)

    let requests = [
        "Tell about London",
        "Compare with New York",
        "Compare the population of the two",
    ]
    let runConfig = RunConfig()
        .tokensLimit(1024)
        .enableThinking(false)

    for request in requests {
        let output = try session.run(
            input: .text(text: request),
            config: runConfig
        ) { _ in
            return true
        }

        print("Request: \(request)")
        print("Response: \(output.text.original.trimmingCharacters(in: .whitespacesAndNewlines))")
        print("-------------------------")
    }
}
```

### Chat with static context

In this example, we will use the static `ContextMode`, which begins with an initial list of messages defining the base context of the conversation, such as predefined instructions. Unlike dynamic mode, this context is fixed and does not evolve with new messages. Each inference request is processed independently, using only the initial context and the latest input, without retaining any previous conversation history.

```swift
import Uzu

func listToString(_ list: [String]) -> String {
    "[" + list.map({ "\"\($0)\"" }).joined(separator: ", ") + "]"
}

public func runChatStaticContext() async throws {
    let engine = try await UzuEngine.create(apiKey: "API_KEY")

    let model = try await engine.chatModel(repoId: "Qwen/Qwen3-0.6B")
    try await engine.downloadChatModel(model) { update in
        print("Progress: \(update.progress)")
    }

    let instructions =
        """
        Your task is to name countries for each city in the given list.
        For example for \(listToString(["Helsenki", "Stockholm", "Barcelona"])) the answer should be \(listToString(["Finland", "Sweden", "Spain"])).
        """
    let config = Config(preset: .general)
        .contextMode(
            .static(
                input: .messages(messages: [Message(role: .system, content: instructions)])
            )
        )
    let session = try engine.chatSession(model, config: config)

    let requests = [
        listToString(["New York", "London", "Lisbon", "Paris", "Berlin"]),
        listToString(["Bangkok", "Tokyo", "Seoul", "Beijing", "Delhi"]),
    ]
    let runConfig = RunConfig()
        .enableThinking(false)

    for request in requests {
        let output = try session.run(
            input: .text(text: request),
            config: runConfig
        ) { _ in
            return true
        }

        print("Request: \(request)")
        print("Response: \(output.text.original.trimmingCharacters(in: .whitespacesAndNewlines))")
        print("-------------------------")
    }
}
```

### Summarization

In this example, we will use the `summarization` preset to generate a summary of the input text:

```swift
import Uzu

public func runSummarization() async throws {
    let engine = try await UzuEngine.create(apiKey: "API_KEY")

    let model = try await engine.chatModel(repoId: "Qwen/Qwen3-0.6B")
    try await engine.downloadChatModel(model) { update in
        print("Progress: \(update.progress)")
    }

    let textToSummarize =
        "A Large Language Model (LLM) is a type of artificial intelligence that processes and generates human-like text. It is trained on vast datasets containing books, articles, and web content, allowing it to understand and predict language patterns. LLMs use deep learning, particularly transformer-based architectures, to analyze text, recognize context, and generate coherent responses. These models have a wide range of applications, including chatbots, content creation, translation, and code generation. One of the key strengths of LLMs is their ability to generate contextually relevant text based on prompts. They utilize self-attention mechanisms to weigh the importance of words within a sentence, improving accuracy and fluency. Examples of popular LLMs include OpenAI's GPT series, Google's BERT, and Meta's LLaMA. As these models grow in size and sophistication, they continue to enhance human-computer interactions, making AI-powered communication more natural and effective."
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

### Cloud

Sometimes you want to create a complex pipeline where some requests are processed on-device and the more complex ones are handled in the cloud using a larger model. With `uzu`, you can do this easily: just choose the cloud model you want to use and perform all requests through the same API:

```swift
import Uzu

public func runCloud() async throws {
    let engine = try await UzuEngine.create(apiKey: "API_KEY")
    let model = try await engine.chatModel(repoId: "openai/gpt-oss-120b")
    let session = try engine.chatSession(model)
    let output = try session.run(
        input: .text(text: "How LLMs work"),
        config: RunConfig()
    ) { _ in
        return true
    }
    print(output.text.original)
}
```

### Structured Output

Sometimes you want the generated output to be valid JSON with predefined fields. You can use `GrammarConfig` to manually specify a JSON schema, or use a struct annotated with `@Generable` from Apple’s FoundationModels framework.

```swift
import FoundationModels
import Uzu

@Generable()
struct Country: Codable {
    let name: String
    let capital: String
}

public func runStructuredOutput() async throws {
    let engine = try await UzuEngine.create(apiKey: "API_KEY")

    let model = try await engine.chatModel(repoId: "Qwen/Qwen3-0.6B")
    try await engine.downloadChatModel(model) { update in
        print("Progress: \(update.progress)")
    }

    let input: Input = .text(
        text:
            "Give me a JSON object containing a list of 3 countries, where each country has name and capital fields"
    )

    let session = try engine.chatSession(model)
    let runConfig = RunConfig()
        .tokensLimit(1024)
        .enableThinking(false)
        .grammarConfig(GrammarConfig.fromType([Country].self))
    let output = try session.run(
        input: input,
        config: runConfig
    ) { _ in
        return true
    }

    guard let countries: [Country] = output.text.parsed.structuredResponse() else {
        return
    }
    print(countries)
}
```

## Troubleshooting

If you experience any problems, please contact us via [Discord](https://discord.com/invite/trymirai) or [email](mailto:contact@getmirai.co).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
