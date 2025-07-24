import Foundation

extension ModelDownloadState {
    public var progress: Double {
        switch self {
        case .downloading(let downloaded, let total),
             .paused(let downloaded, let total):
            guard total > 0 else { return 0 }
            return Double(downloaded) / Double(total)
        case .downloaded:
            return 1.0
        default:
            return 0.0
        }
    }

    public var downloadedBytes: UInt64 {
        switch self {
        case .downloading(let downloaded, _), .paused(let downloaded, _):
            return downloaded
        default:
            return 0
        }
    }

    public var totalBytes: UInt64 {
        switch self {
        case .downloading(_, let total), .paused(_, let total), .downloaded(let total):
            return total
        default:
            return 0
        }
    }

    public var isDownloading: Bool {
        if case .downloading = self { return true }
        return false
    }
} 
