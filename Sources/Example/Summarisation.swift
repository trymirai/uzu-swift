import Foundation
import Uzu

@MainActor public func runSummarisation() async throws {
    let engine = UzuEngine()
    let status = try await engine.activate(apiKey: API_KEY)

    guard status == .activated || status == .gracePeriodActive
    else { throw Error.licenseNotActive(status) }

    let localModelId = "Alibaba-Qwen3-0.6B"

    let modelDownloadState = engine.downloadState(identifier: localModelId)
    let handleDownloadProgress = makeDownloadProgressHandler()
    if modelDownloadState?.phase != .downloaded {
        let handle = engine.downloadHandle(identifier: localModelId)
        try await handle.download()
        let progressStream = handle.progress()
        while let upd = await progressStream.next() {
            handleDownloadProgress(upd)
        }
    }

    // snippet:session-create-summarization
    let modelId: ModelId = .local(id: localModelId)
    let session = try engine.createSession(modelId, config: Config(preset: .summarization))
    // endsnippet:session-create-summarization

    // snippet:session-input-summarization
    let textToSummarize =
        "A Large Language Model (LLM) is a type of AI that processes and generates text using transformer-based architectures trained on vast datasets. They power chatbots, translation, code assistants, and more."
    let input: Input = .text(
        text: "Text is: \"\(textToSummarize)\". Write only summary itself.")
    // endsnippet:session-input-summarization


    let handlePartialOutput = makePartialOutputHandler()

    // snippet:session-run-summarization
    let runConfig = RunConfig()
        .tokensLimit(256)
        .samplingPolicy(.custom(value: .greedy))

    let output = try session.run(
        input: input,
        config: runConfig
    ) { partialOutput in
        // Implement a custom partial output handler
        handlePartialOutput(partialOutput)
    }
    // endsnippet:session-run-summarization

    print("\n--- End of Generation ---")
    print("Final Stats:", output.stats)
}
