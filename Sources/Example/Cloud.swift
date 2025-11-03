import Uzu

public func runCloud() async throws {
    let engine = try await UzuEngine.create(apiKey: "API_KEY")
    let model = try await engine.chatModel(repoId: "openai/gpt-oss-120b")
    let session = try engine.chatSession(model)
    let output = try session.run(
        input: .text(text: "How LLMs work"),
        config: RunConfig()
    ) { _ in
        return true
    }
    print(output.text.original)
}
