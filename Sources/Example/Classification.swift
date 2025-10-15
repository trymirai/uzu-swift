import Foundation
import Uzu

@MainActor public func runClassification() async throws {
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

    let feature = ClassificationFeature(
        name: "sentiment",
        values: ["Happy", "Sad", "Angry", "Fearful", "Surprised", "Disgusted"]
    )
    let config = Config(preset: .classification(feature: feature))

    let session = try engine.createSession(repoId, modelType: .local, config: config)

    let textToDetectFeature =
        "Today's been awesome! Everything just feels right, and I can't stop smiling."
    let prompt =
        "Text is: \"\(textToDetectFeature)\". Choose \(feature.name) from the list: \(feature.values.joined(separator: ", ")). Answer with one word. Don't add a dot at the end."
    let input: Input = .text(text: prompt)

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
