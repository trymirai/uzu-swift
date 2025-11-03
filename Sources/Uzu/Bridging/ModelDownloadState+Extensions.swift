import uzu_plusFFI

extension ModelDownloadState {
    /// Fraction in range 0‒1 of the download that has completed.
    public var progress: Double {
        guard totalKbytes > 0 else { return 0 }
        return Double(downloadedKbytes) / Double(totalKbytes)
    }

    /// Bytes that have already been downloaded.
    public var downloadedBytes: UInt64 {
        UInt64(downloadedKbytes) * 1024
    }

    /// Total size of the download in bytes.
    public var totalBytes: UInt64 {
        UInt64(totalKbytes) * 1024
    }

    /// True iff the download is currently in progress.
    public var isDownloading: Bool {
        phase == .downloading
    }
}
