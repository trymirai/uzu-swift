import Foundation
import Uzu

@MainActor public func exampleChat() async throws {
    // snippet:engine-create
    let engine = UzuEngine()
    let status = try await engine.activate(apiKey: "API_KEY")
    // endsnippet:engine-create

    guard status == .activated || status == .gracePeriodActive else {
        return
    }

    // snippet:model-choose
    let repoId = "Qwen/Qwen3-0.6B"
    // endsnippet:model-choose

    // snippet:model-download
    let modelDownloadState = engine.downloadState(repoId: repoId)
    if modelDownloadState?.phase != .downloaded {
        let handle = try engine.downloadHandle(repoId: repoId)
        try await handle.download()
        let progressStream = handle.progress()
        while let progressUpdate = await progressStream.next() {
            print("Progress: \(progressUpdate.progress)")
        }
    }
    // endsnippet:model-download

    // snippet:session-create-general
    let session = try engine.createSession(
        repoId,
        modelType: .local,
        config: Config(preset: .general)
    )
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
    let engine = UzuEngine()
    let status = try await engine.activate(apiKey: "API_KEY")
    guard status == .activated || status == .gracePeriodActive else {
        return
    }

    let repoId = "Qwen/Qwen3-0.6B"

    let modelDownloadState = engine.downloadState(repoId: repoId)
    if modelDownloadState?.phase != .downloaded {
        let handle = try engine.downloadHandle(repoId: repoId)
        try await handle.download()
        let progressStream = handle.progress()
        while let progressUpdate = await progressStream.next() {
            print("Progress: \(progressUpdate.progress)")
        }
    }

    // snippet:session-create-summarization
    let session = try engine.createSession(
        repoId,
        modelType: .local,
        config: Config(preset: .summarization)
    )
    // endsnippet:session-create-summarization

    // snippet:session-input-summarization
    let textToSummarize =
        "A Large Language Model (LLM) is a type of AI that processes and generates text using transformer-based architectures trained on vast datasets. They power chatbots, translation, code assistants, and more."
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
    let engine = UzuEngine()
    let status = try await engine.activate(apiKey: "API_KEY")
    guard status == .activated || status == .gracePeriodActive else {
        return
    }

    let repoId = "Qwen/Qwen3-0.6B"

    let modelDownloadState = engine.downloadState(repoId: repoId)
    if modelDownloadState?.phase != .downloaded {
        let handle = try engine.downloadHandle(repoId: repoId)
        try await handle.download()
        let progressStream = handle.progress()
        while let progressUpdate = await progressStream.next() {
            print("Progress: \(progressUpdate.progress)")
        }
    }

    // snippet:session-create-classification
    let feature = ClassificationFeature(
        name: "sentiment",
        values: ["Happy", "Sad", "Angry", "Fearful", "Surprised", "Disgusted"]
    )
    let config = Config(preset: .classification(feature: feature))

    let session = try engine.createSession(repoId, modelType: .local, config: config)
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
    try await exampleChat()
    try await exampleSummarization()
    try await exampleClassification()
}
