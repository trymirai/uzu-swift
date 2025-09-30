import Uzu

@MainActor public func runQuickStart() async throws {
    //activate
    let engine = UzuEngine()
    let status = try await engine.activate(apiKey: "API_KEY")
    guard status == .activated || status == .gracePeriodActive else {
        return
    }

    //update models list
    try await engine.updateRegistry()
    let localModelId = "Meta-Llama-3.2-1B-Instruct"

    //download model
    let modelDownloadState = engine.downloadState(identifier: localModelId)
    if modelDownloadState?.phase != .downloaded {
        let handle = try engine.downloadHandle(identifier: localModelId)
        try handle.start()
        let progressStream = try handle.progress()
        while let downloadProgress = await progressStream.next() {
            print("Progress: \(downloadProgress.progress)")
        }
    }

    //create inference session
    let modelId: ModelId = .local(id: localModelId)
    let session = try engine.createSession(modelId, config: .init(preset: .general))

    //create input
    let messages = [
        Message(role: .system, content: "You are a helpful assistant."),
        Message(role: .user, content: "Tell me a short, funny story about a robot."),
    ]
    let input: Input = .messages(messages: messages)

    //run
    let output = try session.run(
        input: input,
        config: RunConfig().tokensLimit(256)
    ) { _ in
        return true
    }
    print("Output: \(output)")
}
