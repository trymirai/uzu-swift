import Uzu

public func runBenchmark() async throws {
    let engine = try await UzuEngine.create(apiKey: "API_KEY")

    let repoId = "LiquidAI/LFM2-700M"
    let model = try await engine.chatModel(repoId: repoId)
    try await engine.downloadChatModel(model) { update in
        print("Progress: \(update.progress)")
    }

    let task = BenchmarksTask(
        identifier: "lfm_test",
        repoId: repoId,
        numberOfRuns: 5,
        tokensLimit: 128,
        messages: [Message(role: .user, content: "Tell about London")],
        greedy: false
    )
    let results = try await engine.benchmark(task)
    print("Prompt t/s, Generate t/s")
    print("----------")
    for result in results {
        print("\(String(format: "%.2f", result.promptTokensPerSecond)), \(String(format: "%.2f", result.generateTokensPerSecond ?? 0.0))")
    }
}
