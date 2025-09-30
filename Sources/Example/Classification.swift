import Foundation
import Uzu

@MainActor public func runClassification() async throws {
    let engine = UzuEngine()
    let status = try await engine.activate(apiKey: API_KEY)

    guard status == .activated || status == .gracePeriodActive
    else { throw Error.licenseNotActive(status) }

    try await engine.updateRegistry()
    let localModelId = "Meta-Llama-3.2-1B-Instruct"

    let modelDownloadState = engine.downloadState(identifier: localModelId)
    let handleDownloadProgress = makeDownloadProgressHandler()
    if modelDownloadState?.phase != .downloaded {
        let handle = try engine.downloadHandle(identifier: localModelId)
        try handle.start()
        let progressStream = try handle.progress()
        while let upd = await progressStream.next() {
            handleDownloadProgress(upd)
        }
    }

    // snippet:session-create-classification
    let feature = ClassificationFeature(
        name: "sentiment",
        values: ["Happy", "Sad", "Angry", "Fearful", "Surprised", "Disgusted"]
    )
    let config = Config(preset: .classification(feature: feature))

    let modelId: ModelId = .local(id: localModelId)
    let session = try engine.createSession(modelId, config: config)
    // endsnippet:session-create-classification

    // snippet:session-input-classification
    let textToDetectFeature =
        "Today's been awesome! Everything just feels right, and I can't stop smiling."
    let prompt =
        "Text is: \"\(textToDetectFeature)\". Choose \(feature.name) from the list: \(feature.values.joined(separator: ", ")). Answer with one word. Don't add a dot at the end."
    let input: Input = .text(text: prompt)
    // endsnippet:session-input-classification

    let handlePartialOutput = makePartialOutputHandler()

    // snippet:session-run-classification
    let runConfig = RunConfig()
        .tokensLimit(32)
        .samplingPolicy(.custom(value: .greedy))

    let output = try session.run(
        input: input,
        config: runConfig
    ) { partialOutput in
        // Implement a custom partial output handler
        handlePartialOutput(partialOutput)
    }
    // endsnippet:session-run-classification

    print("\n--- End of Generation ---")
    print("Final Stats:", output.stats)
}
