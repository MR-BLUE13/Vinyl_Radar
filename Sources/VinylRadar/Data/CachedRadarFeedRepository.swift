import Foundation

public actor CachedRadarFeedRepository: RadarFeedRepository {
    private let cacheStore: any RadarFeedCacheStore

    public init(cacheStore: any RadarFeedCacheStore = UserDefaultsRadarFeedCacheStore()) {
        self.cacheStore = cacheStore
    }

    public func fetchLatest(forceRefresh: Bool = false) async throws -> [ReleaseDrop] {
        await cacheStore.load() ?? []
    }
}
