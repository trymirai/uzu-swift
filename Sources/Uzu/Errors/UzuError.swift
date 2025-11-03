import Foundation

enum UzuError: LocalizedError {
    case licenseNotActivated
    case modelNotFound
    case unexpectedModelType

    var errorDescription: String? {
        switch self {
        case .licenseNotActivated:
            "License not activated, please check your API key"
        case .modelNotFound:
            "Model not found"
        case .unexpectedModelType:
            "Unexpected model type"
        }
    }
}
