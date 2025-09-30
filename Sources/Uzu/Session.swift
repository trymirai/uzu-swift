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
    public typealias ProgressClosure = @Sendable (Output) -> Bool

    private final class ProgressHandlerImpl: Sendable, ProgressHandler {
        private let closure: ProgressClosure

        init(closure: @escaping ProgressClosure) {
            self.closure = closure
        }

        func onProgress(output: Output) -> Bool {
            return closure(output)
        }
    }

    @discardableResult
    public func run(
        input: Input,
        config: RunConfig,
        progress: @escaping ProgressClosure
    ) throws -> Output {
        #if targetEnvironment(simulator)
            throw SimulatorError.notSupported
        #endif

        let callbackObject = ProgressHandlerImpl(closure: progress)
        return try self.run(
            input: input,
            config: config,
            progress: callbackObject
        )
    }
}
