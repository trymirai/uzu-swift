import Foundation
import Uzu

/// Visit https://platform.trymirai.com/ to get your API key.
let apiKey = "MIRAI_API_KEY"
let resolvedApiKey = ProcessInfo.processInfo.environment["MIRAI_API_KEY"] ?? apiKey

public enum Error: Swift.Error {
    case licenseNotActive(LicenseStatus)
}

// MARK: - Streaming helpers

@MainActor
public final class PartialOutputHandler {
    private var printedChars: Int = 0

    public init() {}

    public func handle(_ partial: SessionOutput) -> Bool {
        let text = partial.text
        if printedChars < text.count {
            let start = text.index(text.startIndex, offsetBy: printedChars)
            let newChunk = text[start...]
            if !newChunk.isEmpty {
                FileHandle.standardOutput.write(Data(newChunk.utf8))
                printedChars = text.count
            }
        }
        return true
    }
}

@MainActor
public func makePartialOutputHandler() -> (SessionOutput) -> Bool {
    let handler = PartialOutputHandler()
    return { partial in handler.handle(partial) }
}

// MARK: - Progress bar

@MainActor
public final class ProgressBar {
    private let width: Int
    private let desc: String
    private var lastPrinted: (n: Double, time: TimeInterval) = (0, 0)
    private let minIntervalSeconds: TimeInterval = 0.08
    private var startTime: TimeInterval = CFAbsoluteTimeGetCurrent()

    public init(width: Int = 40, desc: String = "Downloading") {
        self.width = max(10, width)
        self.desc = desc
    }

    public func update(completedBytes: Double, totalBytes: Double?) {
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastPrinted.time < minIntervalSeconds { return }
        lastPrinted = (completedBytes, now)

        let progress: Double
        if let total = totalBytes, total > 0 {
            progress = max(0, min(1, completedBytes / total))
        } else {
            progress = max(0, min(1, completedBytes)) // already normalized
        }

        let filled = Int((Double(width) * progress).rounded(.down))
        let empty = max(0, width - filled)
        let bar = String(repeating: "█", count: filled) + String(repeating: "░", count: empty)

        let pct = Int((progress * 100).rounded())

        let elapsed = now - startTime
        let elapsedStr = formatInterval(elapsed)
        let remainingStr: String
        if progress > 0 {
            let eta = (elapsed / progress) - elapsed
            remainingStr = formatInterval(max(0, eta))
        } else {
            remainingStr = "--:--"
        }

        let formatTotalNumber: String
        if let total = totalBytes { formatTotalNumber = formatNumber(total) } else { formatTotalNumber = "?" }
        let formatNumber = formatNumber(completedBytes)

        let line = "\(desc) [\(bar)] \(pct)% | \(formatNumber)/\(formatTotalNumber) [\(elapsedStr)<\(remainingStr)]"
        fputs("\r" + line, stdout)
        fflush(stdout)
    }

    public func close() {
        fputs("\n", stdout)
        fflush(stdout)
    }

    private func formatInterval(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }

    private func formatNumber(_ n: Double) -> String {
        let absn = abs(n)
        switch absn {
        case 1_000_000_000...: return String(format: "%.1fB", n / 1_000_000_000)
        case 1_000_000...: return String(format: "%.1fM", n / 1_000_000)
        case 1_000...: return String(format: "%.1fK", n / 1_000)
        default: return String(format: "%.0f", n)
        }
    }
}

@MainActor
public final class ProgressPrinter {
    private let bar = ProgressBar()
    public init() {}

    public func handle(_ upd: ProgressUpdate) {
        // Prefer totalBytes if present; fallback to normalized progress
        if let total = upd.totalBytes, total > 0 {
            bar.update(completedBytes: upd.completedBytes, totalBytes: total)
        } else {
            bar.update(completedBytes: upd.progress, totalBytes: 1)
        }
        if upd.progress >= 1.0 { bar.close() }
    }
}

@MainActor
public func makeDownloadProgressHandler() -> (ProgressUpdate) -> Void {
    let printer = ProgressPrinter()
    return { upd in printer.handle(upd) }
}
