import Foundation
import Uzu

public func runClassification() async throws {
    let engine = try await UzuEngine.create(apiKey: "API_KEY")

    let model = try await engine.chatModel(repoId: "Qwen/Qwen3-0.6B")
    try await engine.downloadChatModel(model) { update in
        print("Progress: \(update.progress)")
    }

    let feature = ClassificationFeature(
        name: "sentiment",
        values: ["Happy", "Sad", "Angry", "Fearful", "Surprised", "Disgusted"]
    )
    let textToDetectFeature =
        "Today's been awesome! Everything just feels right, and I can't stop smiling."
    let prompt =
        "Text is: \"\(textToDetectFeature)\". Choose \(feature.name) from the list: \(feature.values.joined(separator: ", ")). Answer with one word. Don't add a dot at the end."
    let input: Input = .text(text: prompt)

    let config = Config(preset: .classification(feature: feature))
    let session = try engine.chatSession(model, config: config)
    let runConfig = RunConfig()
        .tokensLimit(32)
        .enableThinking(false)
        .samplingPolicy(.custom(value: .greedy))
    let output = try session.run(
        input: input,
        config: runConfig
    ) { _ in
        return true
    }
    
    print("Prediction: \(output.text.original)")
    print("Stats: \(output.stats)")
}
