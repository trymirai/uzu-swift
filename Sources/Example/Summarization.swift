import Foundation
import Uzu

@MainActor public func runSummarization() async throws {
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

    let session = try engine.createSession(
        repoId,
        modelType: .local,
        config: Config(preset: .summarization)
    )

    let textToSummarize =
        "A Large Language Model (LLM) is a type of AI that processes and generates text using transformer-based architectures trained on vast datasets. They power chatbots, translation, code assistants, and more."
    let input: Input = .text(
        text: "Text is: \"\(textToSummarize)\". Write only summary itself.")

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
