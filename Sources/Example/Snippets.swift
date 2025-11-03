import Foundation
import Uzu

@MainActor public func exampleQuickStart() async throws {
    // snippet:quick-start
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
    // endsnippet:quick-start

    print(output.text.original)
}

@MainActor public func exampleChat() async throws {
    // snippet:engine-create
    let engine = try await UzuEngine.create(apiKey: "API_KEY")
    // endsnippet:engine-create

    // snippet:model-choose
    let model = try await engine.chatModel(repoId: "Qwen/Qwen3-0.6B")
    // endsnippet:model-choose

    // snippet:model-download
    try await engine.downloadChatModel(model) { update in
        print("Progress: \(update.progress)")
    }
    // endsnippet:model-download

    // snippet:session-create-general
    let session = try engine.chatSession(model, config: Config(preset: .general))
    // endsnippet:session-create-general

    // snippet:session-input-general
    let messages = [
        Message(role: .system, content: "You are a helpful assistant."),
        Message(role: .user, content: "Tell me a short, funny story about a robot."),
    ]
    let input: Input = .messages(messages: messages)
    // endsnippet:session-input-general

    // snippet:session-run-general
    let runConfig = RunConfig()
        .tokensLimit(1024)

    let output = try session.run(
        input: input,
        config: runConfig
    ) { _ in
        return true
    }
    // endsnippet:session-run-general

    print(output.text.original)
}

@MainActor public func exampleSummarization() async throws {
    let engine = try await UzuEngine.create(apiKey: "API_KEY")

    let model = try await engine.chatModel(repoId: "Qwen/Qwen3-0.6B")
    try await engine.downloadChatModel(model) { update in
        print("Progress: \(update.progress)")
    }

    // snippet:session-create-summarization
    let session = try engine.chatSession(model, config: Config(preset: .summarization))
    // endsnippet:session-create-summarization

    // snippet:session-input-summarization
    let textToSummarize =
        "A Large Language Model (LLM) is a type of artificial intelligence that processes and generates human-like text. It is trained on vast datasets containing books, articles, and web content, allowing it to understand and predict language patterns. LLMs use deep learning, particularly transformer-based architectures, to analyze text, recognize context, and generate coherent responses. These models have a wide range of applications, including chatbots, content creation, translation, and code generation. One of the key strengths of LLMs is their ability to generate contextually relevant text based on prompts. They utilize self-attention mechanisms to weigh the importance of words within a sentence, improving accuracy and fluency. Examples of popular LLMs include OpenAI's GPT series, Google's BERT, and Meta's LLaMA. As these models grow in size and sophistication, they continue to enhance human-computer interactions, making AI-powered communication more natural and effective."
    let input: Input = .text(
        text: "Text is: \"\(textToSummarize)\". Write only summary itself.")
    // endsnippet:session-input-summarization

    // snippet:session-run-summarization
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
    // endsnippet:session-run-summarization

    print("Summary: \(output.text.original)")
    print(
        "Model runs: \(output.stats.prefillStats.modelRun.count + (output.stats.generateStats?.modelRun.count ?? 0))"
    )
    print("Tokens count: \(output.stats.totalStats.tokensCountOutput)")
}

@MainActor public func exampleClassification() async throws {
    let engine = try await UzuEngine.create(apiKey: "API_KEY")

    let model = try await engine.chatModel(repoId: "Qwen/Qwen3-0.6B")
    try await engine.downloadChatModel(model) { update in
        print("Progress: \(update.progress)")
    }

    // snippet:session-create-classification
    let feature = ClassificationFeature(
        name: "sentiment",
        values: ["Happy", "Sad", "Angry", "Fearful", "Surprised", "Disgusted"]
    )
    let config = Config(preset: .classification(feature: feature))

    let session = try engine.chatSession(model, config: config)
    // endsnippet:session-create-classification

    // snippet:session-input-classification
    let textToDetectFeature =
        "Today's been awesome! Everything just feels right, and I can't stop smiling."
    let prompt =
        "Text is: \"\(textToDetectFeature)\". Choose \(feature.name) from the list: \(feature.values.joined(separator: ", ")). Answer with one word. Don't add a dot at the end."
    let input: Input = .text(text: prompt)
    // endsnippet:session-input-classification

    // snippet:session-run-classification
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
    // endsnippet:session-run-classification

    print("Prediction: \(output.text.original)")
    print("Stats: \(output.stats)")
}

@MainActor public func runSnippets() async throws {
    try await exampleQuickStart()
    try await exampleChat()
    try await exampleSummarization()
    try await exampleClassification()
}
