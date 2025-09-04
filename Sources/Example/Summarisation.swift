import Foundation
import Uzu

@MainActor public func runSummarisation() async throws {
    let engine = UzuEngine()
    let status = try await engine.activate(apiKey: resolvedApiKey)

    guard status == .activated || status == .gracePeriodActive
    else { throw Error.licenseNotActive(status) }

    try await engine.updateRegistry()
    let localModelId = "Meta-Llama-3.2-1B-Instruct-bfloat16"

    let modelDownloadState = engine.downloadState(identifier: localModelId)
    let handleDownloadProgress = makeDownloadProgressHandler()
    if modelDownloadState?.phase != .downloaded {
        let handle = try engine.downloadHandle(identifier: localModelId)
        try handle.start()
        let progressStream = try handle.progress()
        while let upd = await progressStream.next() {
            handleDownloadProgress(upd)
        }
    }

    let modelId: ModelId = .local(id: localModelId)
    let session = try engine.createSession(modelId)

    // snippet:session-load
    try session.load(
        preset: .summarization,
        samplingSeed: .default,
        contextLength: .default
    )
    // endsnippet:session-load

    let textToSummarize =
        "A Large Language Model (LLM) is a type of AI that processes and generates text using transformer-based architectures trained on vast datasets. They power chatbots, translation, code assistants, and more."
    // snippet:session-input
    let input: SessionInput = .text(
        text: "Text is: \"\(textToSummarize)\". Write only summary itself.")
    // endsnippet:session-input

    // snippet:session-run-config
    let tokensLimit: UInt32 = 256
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
