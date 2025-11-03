import Foundation

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
