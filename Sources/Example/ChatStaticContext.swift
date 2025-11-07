import Uzu

func listToString(_ list: [String]) -> String {
    "[" + list.map({ "\"\($0)\"" }).joined(separator: ", ") + "]"
}

public func runChatStaticContext() async throws {
    let engine = try await UzuEngine.create(apiKey: "API_KEY")

    let model = try await engine.chatModel(repoId: "Qwen/Qwen3-0.6B")
    try await engine.downloadChatModel(model) { update in
        print("Progress: \(update.progress)")
    }

    let instructions =
        """
        Your task is to name countries for each city in the given list.
        For example for \(listToString(["Helsenki", "Stockholm", "Barcelona"])) the answer should be \(listToString(["Finland", "Sweden", "Spain"])).
        """
    let config = Config(preset: .general)
        .contextMode(
            .static(
                input: .messages(messages: [Message(role: .system, content: instructions)])
            )
        )
    let session = try engine.chatSession(model, config: config)

    let requests = [
        listToString(["New York", "London", "Lisbon", "Paris", "Berlin"]),
        listToString(["Bangkok", "Tokyo", "Seoul", "Beijing", "Delhi"]),
    ]
    let runConfig = RunConfig()
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
