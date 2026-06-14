import Foundation

actor RadarArtworkLoader {
    static let shared = RadarArtworkLoader()

    private let cacheStore: any ArtworkCacheStore
    private var memoryCache: [URL: Data] = [:]

    init(cacheStore: any ArtworkCacheStore = FileArtworkCacheStore()) {
        self.cacheStore = cacheStore
    }

    func loadData(for url: URL) async -> Data? {
        if let cachedInMemory = memoryCache[url] {
            return cachedInMemory
        }

        if let cachedOnDisk = await cacheStore.load(for: url), !cachedOnDisk.isEmpty {
            memoryCache[url] = cachedOnDisk
            return cachedOnDisk
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard !data.isEmpty else { return nil }
            if let httpResponse = response as? HTTPURLResponse,
               !(200..<300).contains(httpResponse.statusCode) {
                return nil
            }

            memoryCache[url] = data
            await cacheStore.save(data, for: url)
            return data
        } catch {
            return nil
        }
    }
}
