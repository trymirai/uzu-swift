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
