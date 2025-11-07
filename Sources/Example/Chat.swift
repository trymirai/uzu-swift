import Uzu

public func runChat() async throws {
    let engine = try await UzuEngine.create(apiKey: "API_KEY")

    let model = try await engine.chatModel(repoId: "Qwen/Qwen3-0.6B")
    try await engine.downloadChatModel(model) { update in
        print("Progress: \(update.progress)")
    }

    let messages = [
        Message(role: .system, content: "You are a helpful assistant."),
        Message(role: .user, content: "Tell me a short, funny story about a robot."),
    ]
    let input: Input = .messages(messages: messages)

    let session = try engine.chatSession(model)
    let runConfig = RunConfig()
        .tokensLimit(1024)
    let output = try session.run(
        input: input,
        config: runConfig
    ) { _ in
        return true
    }
    
    print(output.text.original)
}
