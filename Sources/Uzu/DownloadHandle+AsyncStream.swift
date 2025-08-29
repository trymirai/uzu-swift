import Foundation

public extension DownloadHandle {
    /// Convenience: expose download progress as an AsyncThrowingStream of Double (0.0...1.0).
    func progressStream() throws -> AsyncThrowingStream<Double, Swift.Error> {
        let progressStream = try self.progress()
        return AsyncThrowingStream<Double, Swift.Error> { continuation in
            let task = Task {
                while !Task.isCancelled {
                    let update = await progressStream.next()
                    guard let update else {
                        continuation.finish()
                        break
                    }
                    continuation.yield(update.progress)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}


