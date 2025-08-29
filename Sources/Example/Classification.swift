import Foundation
import Uzu

@MainActor public func runClassification() async throws {
    let engine = UzuEngine()
    let status = try await engine.activate(apiKey: apiKey)

    guard status == .activated || status == .gracePeriodActive
    else { throw Error.licenseNotActive(status) }

    try await engine.updateRegistry()
    let localModelId = "Meta-Llama-3.2-1B-Instruct-bfloat16"

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

    let modelId: ModelId = .local(id: localModelId)
    let session = try engine.createSession(modelId)

    // snippet:classification-feature
    let feature = SessionClassificationFeature(
        name: "sentiment",
        values: ["Happy", "Sad", "Angry", "Fearful", "Surprised", "Disgusted"]
    )
    // endsnippet:classification-feature

    // snippet:session-load
    try session.load(
        preset: .classification(feature: feature),
        samplingSeed: .default,
        contextLength: .default
    )
    // endsnippet:session-load

    // snippet:session-input
    let textToDetectFeature =
        "Today's been awesome! Everything just feels right, and I can't stop smiling."
    let prompt =
        "Text is: \"\(textToDetectFeature)\". Choose \(feature.name) from the list: \(feature.values.joined(separator: ", ")). Answer with one word. Don't add a dot at the end."
    let input: SessionInput = .text(text: prompt)
    // endsnippet:session-input

    // snippet:session-run-config
    let tokensLimit: UInt32 = 32
    let sampling: SamplingConfig = .argmax
    // endsnippet:session-run-config


    let handlePartialOutput = makePartialOutputHandler()

    // snippet:session-run
    let output = try session.run(
        input: input,
        tokensLimit: tokensLimit,
        samplingConfig: sampling
    ) { partialOutput in handlePartialOutput(partialOutput) }
    // endsnippet:session-run

    print("\n--- End of Generation ---")
    print("Final Stats:", output.stats)
}
