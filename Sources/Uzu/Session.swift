import Foundation
import uzu_plusFFI

#if targetEnvironment(simulator)
enum SimulatorError: LocalizedError {
    case notSupported
    
    var errorDescription: String? {
        switch self {
        case .notSupported:
            "iOS Simulator is not supported due to Metal Restrictions"
        }
    }
}
#endif

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
        
        #if targetEnvironment(simulator)
        throw SimulatorError.notSupported
        #else
        try self.load(config: config)
        #endif
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
        tokensLimit: UInt32 = 128,
        samplingMethod: SamplingConfig = .argmax,
        progress: @escaping ProgressClosure
    ) -> SessionOutput {
        #if targetEnvironment(simulator)
        SessionOutput(
            text: "",
            stats: SessionOutputStats(
                prefillStats: SessionOutputStepStats(
                    duration: 0,
                    suffixLength: 0,
                    tokensCount: 0,
                    tokensPerSecond: 0,
                    modelRun: SessionOutputRunStats(
                        count: 0,
                        averageDuration: 0
                    ),
                    run: .none
                ),
                generateStats: .none,
                totalStats: SessionOutputTotalStats(
                    duration: 0,
                    tokensCountInput: 0,
                    tokensCountOutput: 0
                )
            ),
            finishReason: .none
        )
        #else
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
        #endif
    }
}
