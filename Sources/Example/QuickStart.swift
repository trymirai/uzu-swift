import Uzu

@MainActor public func runQuickStart() async throws {
    //activate
    let engine = UzuEngine()
    let status = try await engine.activate(apiKey: "API_KEY")
    guard status == .activated || status == .gracePeriodActive else {
        return
    }

    //choose model
    let repoId = "Qwen/Qwen3-0.6B"

    //download model
    let modelDownloadState = engine.downloadState(repoId: repoId)
    if modelDownloadState?.phase != .downloaded {
        let handle = try engine.downloadHandle(repoId: repoId)
        try await handle.download()
        let progressStream = handle.progress()
        while let progressUpdate = await progressStream.next() {
            print("Progress: \(progressUpdate.progress)")
        }
    }

    //create session
    let session = try engine.createSession(
        repoId,
        modelType: .local,
        config: .init(preset: .general)
    )

    //create input
    let messages = [
        Message(role: .system, content: "You are a helpful assistant."),
        Message(role: .user, content: "Tell me a short, funny story about a robot."),
    ]
    let input: Input = .messages(messages: messages)

    //run
    let output = try session.run(
        input: input,
        config: RunConfig()
    ) { _ in
        return true
    }
    print(output.text.original)
}
