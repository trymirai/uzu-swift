import Foundation
import Uzu

@MainActor public func runChat() async throws {

    // snippet:activation

    let engine = UzuEngine()
    let status = try await engine.activate(apiKey: resolvedApiKey)

    // endsnippet:activation

    guard status == .activated || status == .gracePeriodActive
    else { throw Error.licenseNotActive(status) }

    // snippet:registry

    try await engine.updateRegistry()
    let localModelId = "Meta-Llama-3.2-1B-Instruct-bfloat16"

    // endsnippet:registry

    // snippet:model-state

    // try engine.download(identifier: localModelId)
    // engine.pause(identifier: localModelId)
    // engine.resume(identifier: localModelId)
    // engine.stop(identifier: localModelId)
    // engine.delete(identifier: localModelId)

    let modelDownloadState = engine.downloadState(identifier: localModelId)

    // endsnippet:model-state

    let handleDownloadProgress = makeDownloadProgressHandler()

    if modelDownloadState?.phase != .downloaded {
        // snippet:download
        let handle = try engine.downloadHandle(identifier: localModelId)
        try handle.start()
        let progressStream = try handle.progress()
        while let downloadProgress = await progressStream.next() {
            handleDownloadProgress(downloadProgress)
        }
        // endsnippet:download
    }

    // snippet:session-create
    let modelId: ModelId = .local(id: localModelId)
    let session = try engine.createSession(modelId)
    // endsnippet:session-create

    // snippet:session-load
    try session.load(
        preset: .general,
        samplingSeed: .default,
        contextLength: .default
    )
    // endsnippet:session-load

    // snippet:session-input
    let messages = [
        SessionMessage(role: .system, content: "You are a helpful assistant."),
        SessionMessage(role: .user, content: "Tell me a short, funny story about a robot."),
    ]
    let input: SessionInput = .messages(messages: messages)
    // endsnippet:session-input

    // snippet:session-run-config
    let tokensLimit: UInt32 = 128
    let sampling: SamplingConfig = .argmax
    // endsnippet:session-run-config

    let handlePartialOutput = makePartialOutputHandler()

    // snippet:session-run
    let output = try session.run(
        input: input,
        tokensLimit: tokensLimit,
        samplingConfig: sampling
    ) { partialOutput in handlePartialOutput(partialOutput) }
    // endsnippet:session-run

    print("\n--- End of Generation ---")
    print("Final Stats:", output.stats)
}
