import XCTest
@testable import Uzu

@MainActor
final class UzuEngineDownloadTests: XCTestCase {
    func testDownloadLlamaModel() async throws {
        let engine = UzuEngine()
        let identifier = "Alibaba-Qwen3-0.6B"

        let expectation = XCTestExpectation(description: "Model downloaded")

        Task {
            do {
                let handle = engine.downloadHandle(identifier: identifier)
                try await handle.download()
                let stream = handle.progress()
                while let update = await stream.next() {
                    let progress = update.progress
                    print("Progress: \(Int(progress * 100))%")
                }
                expectation.fulfill()
            } catch {
                XCTFail("Download failed with error: \(error.localizedDescription)")
            }
        }

        await fulfillment(of: [expectation], timeout: 600.0)
    }
} 
