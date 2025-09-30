#if !targetEnvironment(simulator)
    import Foundation
    import uzu_plusFFI

    // MARK: - Custom LocalizedError

    extension Uzu.EngineError: LocalizedError {
        public var errorDescription: String? {
            // Delegate to the Rust-provided helper for a human-readable message.
            Uzu.errorUserDescription(err: self)
        }
    }
#endif
