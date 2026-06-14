import Foundation

public actor CachedFirstRadarFeedRepository: RadarFeedRepository {
    private let remote: any RadarFeedRepository
    private let cacheStore: any RadarFeedCacheStore

    public init(
        remote: any RadarFeedRepository,
        cacheStore: any RadarFeedCacheStore = UserDefaultsRadarFeedCacheStore()
    ) {
        self.remote = remote
        self.cacheStore = cacheStore
    }

    public func fetchLatest(forceRefresh: Bool) async throws -> [ReleaseDrop] {
        if forceRefresh {
            return try await remote.fetchLatest(forceRefresh: true)
        }

        if let cached = await cacheStore.load(), !cached.isEmpty {
            return cached
        }

        return try await remote.fetchLatest(forceRefresh: false)
    }
}
