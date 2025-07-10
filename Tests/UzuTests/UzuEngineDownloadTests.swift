import XCTest
@testable import Uzu

@MainActor
final class UzuEngineDownloadTests: XCTestCase {
    func testDownloadLlamaModel() async throws {
        let engine = UzuEngine(apiKey: "")
        let identifier = "Alibaba-Qwen2.5-0.5B-Instruct-float16"

        let expectation = XCTestExpectation(description: "Model downloaded")

        Task {
            do {
                let handle = try engine.downloadHandle(identifier: identifier)
                try handle.startDownload()
                for try await progress in handle.progress {
                    print("Progress: \(Int(progress * 100))%")
                    if progress >= 1.0 {
                        expectation.fulfill()
                        return
                    }
                }
            } catch {
                XCTFail("Download failed with error: \(error.localizedDescription)")
            }
        }

        await fulfillment(of: [expectation], timeout: 600.0)
    }
} 
