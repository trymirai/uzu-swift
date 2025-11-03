import uzu_plusFFI

extension ChatSession {
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
