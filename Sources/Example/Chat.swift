import Foundation
import Uzu

@MainActor public func runChat() async throws {

    // snippet:activation
    let engine = UzuEngine()
    let status = try await engine.activate(apiKey: API_KEY)
    // endsnippet:activation

    guard status == .activated || status == .gracePeriodActive
    else { throw Error.licenseNotActive(status) }

    // snippet:registry
    try await engine.updateRegistry()
    let _ = engine.localModels
    let localModelId = "Meta-Llama-3.2-1B-Instruct"
    // endsnippet:registry

    // snippet:storage-methods
    let modelDownloadState = engine.downloadState(identifier: localModelId)

    // try engine.download(identifier: localModelId)
    // engine.pause(identifier: localModelId)
    // engine.resume(identifier: localModelId)
    // engine.stop(identifier: localModelId)
    // engine.delete(identifier: localModelId)
    // endsnippet:storage-methods

    let handleDownloadProgress = makeDownloadProgressHandler()
    if modelDownloadState?.phase != .downloaded {
        // snippet:download-handle
        let handle = try engine.downloadHandle(identifier: localModelId)
        try handle.start()
        let progressStream = try handle.progress()
        while let downloadProgress = await progressStream.next() {
            // Implement a custom download progress handler
            handleDownloadProgress(downloadProgress)
        }
        // endsnippet:download-handle
    }

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
