import Foundation

extension ModelState {
    public var progress: Double {
        switch self {
        case .downloading(let p), .paused(let p):
            return p
        case .downloaded:
            return 1.0
        default:
            return 0.0
        }
    }

    public var isDownloading: Bool {
        if case .downloading = self { return true }
        return false
    }
} 
