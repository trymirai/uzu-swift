import Uzu

public func runSSM() async throws {
    let engine = try await UzuEngine.create(apiKey: "API_KEY")

    let model = try await engine.chatModel(repoId: "cartesia-ai/Llamba-1B")
    try await engine.downloadChatModel(model) { update in
        print("Progress: \(update.progress)")
    }

    let session = try engine.chatSession(model)
    let output = try session.run(
        input: .text(text: "Tell me a short, funny story about a robot"),
        config: RunConfig()
    ) { _ in
        return true
    }

    print(output.text.original)
}
