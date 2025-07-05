import Foundation
import uzu_plusFFI

// MARK: - Custom LocalizedError

extension Uzu.Error: LocalizedError {
    public var errorDescription: String? {
        // Delegate to the Rust-provided helper for a human-readable message.
        Uzu.errorUserDescription(err: self)
    }
}
