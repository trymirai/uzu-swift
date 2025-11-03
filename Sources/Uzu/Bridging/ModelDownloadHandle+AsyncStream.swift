import uzu_plusFFI

extension ModelDownloadHandle {
    public func progressStream() -> AsyncThrowingStream<Double, Swift.Error> {
        let progressStream = self.progress()
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


