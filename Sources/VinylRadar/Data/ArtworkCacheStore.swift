import CryptoKit
import Foundation

protocol ArtworkCacheStore: Sendable {
    func load(for url: URL) async -> Data?
    func save(_ data: Data, for url: URL) async
}

actor FileArtworkCacheStore: ArtworkCacheStore {
    private let fileManager: FileManager
    private let rootURL: URL
    private let maxTotalBytes: Int64

    init(
        fileManager: FileManager = .default,
        directoryName: String = "vinyl_artwork",
        maxTotalBytes: Int64 = 150 * 1024 * 1024
    ) {
        self.fileManager = fileManager
        self.maxTotalBytes = maxTotalBytes

        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.rootURL = base.appendingPathComponent(directoryName, isDirectory: true)

        if !fileManager.fileExists(atPath: rootURL.path) {
            try? fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
        }
    }

    func load(for url: URL) async -> Data? {
        let fileURL = cachedFileURL(for: url)
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        try? fileManager.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: fileURL.path
        )
        return data
    }

    func save(_ data: Data, for url: URL) async {
        let fileURL = cachedFileURL(for: url)
        try? data.write(to: fileURL, options: [.atomic])
        trimIfNeeded()
    }

    private func trimIfNeeded() {
        let keys: Set<URLResourceKey> = [.contentModificationDateKey, .fileSizeKey, .isRegularFileKey]
        guard let urls = try? fileManager.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        var entries: [(url: URL, modifiedAt: Date, size: Int64)] = []
        var total: Int64 = 0

        for url in urls {
            guard let values = try? url.resourceValues(forKeys: keys),
                  values.isRegularFile == true else {
                continue
            }

            let size = Int64(values.fileSize ?? 0)
            let modifiedAt = values.contentModificationDate ?? .distantPast
            entries.append((url, modifiedAt, size))
            total += size
        }

        guard total > maxTotalBytes else {
            return
        }

        for entry in entries.sorted(by: { $0.modifiedAt < $1.modifiedAt }) {
            guard total > maxTotalBytes else {
                break
            }
            try? fileManager.removeItem(at: entry.url)
            total -= entry.size
        }
    }

    private func cachedFileURL(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let key = digest.map { String(format: "%02x", $0) }.joined()
        let ext = sanitizedExtension(from: url.pathExtension)
        return rootURL.appendingPathComponent(ext.isEmpty ? key : "\(key).\(ext)")
    }

    private func sanitizedExtension(from raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let allowed = trimmed.filter { $0.isLetter || $0.isNumber }
        return allowed
    }
}
