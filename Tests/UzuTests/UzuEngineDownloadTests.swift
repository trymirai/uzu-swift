import XCTest
@testable import Uzu

@MainActor
final class UzuEngineDownloadTests: XCTestCase {
    func testDownloadModel() async throws {
        let engine = try await UzuEngine.create(apiKey: "API_KEY")
        let model = try await engine.chatModel(repoId: "Qwen/Qwen3-0.6B", types: [.local])

        let expectation = XCTestExpectation(description: "Model downloaded")

        Task {
            do {
                try await engine.downloadChatModel(model)
                expectation.fulfill()
            } catch {
                XCTFail("Download failed with error: \(error.localizedDescription)")
            }
        }

        await fulfillment(of: [expectation], timeout: 600.0)
    }
} 
