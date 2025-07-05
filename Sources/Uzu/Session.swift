import Foundation
import uzu_plusFFI

extension Session {

    public typealias ProgressClosure = @Sendable (SessionOutput) -> Bool

    convenience init(modelURL: URL) throws {
        let modelDir = modelURL.standardizedFileURL.path
        try self.init(modelDir: modelDir)
    }

    public func load(
        preset: SessionPreset = .general,
        samplingSeed: SamplingSeed = .default,
        contextLength: ContextLength = .default
    ) throws {
        let config = SessionConfig(
            preset: preset,
            samplingSeed: samplingSeed,
            contextLength: contextLength
        )
        try self.load(config: config)
    }

    private final class ProgressHandlerImpl: Sendable, SessionProgressHandler {
        private let closure: ProgressClosure

        init(closure: @escaping ProgressClosure) {
            self.closure = closure
        }

        func onProgress(output: SessionOutput) -> Bool {
            return closure(output)
        }
    }

    @discardableResult
    public func run(
        input: SessionInput,
        tokensLimit: UInt32 = 1024,
        samplingMethod: SamplingConfig = .argmax,
        progress: @escaping ProgressClosure
    ) -> SessionOutput {
        let runConfig = SessionRunConfig(
            tokensLimit: UInt64(tokensLimit),
            samplingMethod: samplingMethod
        )
        let callbackObject = ProgressHandlerImpl(closure: progress)
        return self.run(
            input: input,
            runConfig: runConfig,
            progressCallback: callbackObject
        )
    }
}
