import FoundationModels
import Uzu

@Generable()
struct Country: Codable {
    let name: String
    let capital: String
}

public func runStructuredOutput() async throws {
    let engine = try await UzuEngine.create(apiKey: "API_KEY")

    let model = try await engine.chatModel(repoId: "Qwen/Qwen3-0.6B")
    try await engine.downloadChatModel(model) { update in
        print("Progress: \(update.progress)")
    }

    let input: Input = .text(
        text:
            "Give me a JSON object containing a list of 3 countries, where each country has name and capital fields"
    )

    let session = try engine.chatSession(model)
    let runConfig = RunConfig()
        .tokensLimit(1024)
        .enableThinking(false)
        .grammarConfig(GrammarConfig.fromType([Country].self))
    let output = try session.run(
        input: input,
        config: runConfig
    ) { _ in
        return true
    }

    guard let countries: [Country] = output.text.parsed.structuredResponse() else {
        return
    }
    print(countries)
}
