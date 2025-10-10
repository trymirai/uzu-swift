import Foundation
import Uzu

@MainActor public func runChat() async throws {

    // snippet:engine-create
    let engine = UzuEngine()
    let status = try await engine.activate(apiKey: API_KEY)
    // endsnippet:engine-create

    guard status == .activated || status == .gracePeriodActive
    else { throw Error.licenseNotActive(status) }

    // snippet:model-choose
    let localModels = engine.localModels
    let localModelId = "Alibaba-Qwen3-0.6B"
    // endsnippet:model-choose

    // snippet:model-download
    let modelDownloadState = engine.downloadState(identifier: localModelId)
    let handleDownloadProgress = makeDownloadProgressHandler()

    if modelDownloadState?.phase != .downloaded {
        let handle = engine.downloadHandle(identifier: localModelId)
        try await handle.download()
        let progressStream = handle.progress()
        while let downloadProgress = await progressStream.next() {
            handleDownloadProgress(downloadProgress)
        }
    }
    // endsnippet:model-download

    // snippet:session-create-general
    let modelId: ModelId = .local(id: localModelId)
    let session = try engine.createSession(modelId, config: Config(preset: .general))
    // endsnippet:session-create-general

    // snippet:session-input-general
    let messages = [
        Message(role: .system, content: "You are a helpful assistant."),
        Message(role: .user, content: "Tell me a short, funny story about a robot."),
    ]
    let input: Input = .messages(messages: messages)
    // endsnippet:session-input-general

    let handlePartialOutput = makePartialOutputHandler()

    // snippet:session-run-general
    let runConfig = RunConfig()
        .tokensLimit(128)

    let output = try session.run(
        input: input,
        config: runConfig
    ) { partialOutput in
        // Implement a custom partial output handler
        handlePartialOutput(partialOutput)
    }
    // endsnippet:session-run-general

    print("\n--- End of Generation ---")
    print("Final Stats:", output.stats)
}
