import Uzu

public func runChatDynamicContext() async throws {
    let engine = try await UzuEngine.create(apiKey: "API_KEY")

    let model = try await engine.chatModel(repoId: "Qwen/Qwen3-0.6B")
    try await engine.downloadChatModel(model) { update in
        print("Progress: \(update.progress)")
    }

    let config = Config(preset: .general)
        .contextMode(.dynamic)
    let session = try engine.chatSession(model, config: config)

    let requests = [
        "Tell about London",
        "Compare with New York",
        "Compare the population of the two",
    ]
    let runConfig = RunConfig()
        .tokensLimit(1024)
        .enableThinking(false)

    for request in requests {
        let output = try session.run(
            input: .text(text: request),
            config: runConfig
        ) { _ in
            return true
        }

        print("Request: \(request)")
        print("Response: \(output.text.original.trimmingCharacters(in: .whitespacesAndNewlines))")
        print("-------------------------")
    }
}
