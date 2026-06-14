import Foundation
import Testing
@testable import VinylRadar

@Suite("CachedRadarFeedRepositoryTests")
struct CachedRadarFeedRepositoryTests {
    @Test("returns cached releases when cache exists")
    func returnCache() async throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let cached = [
            makeRelease(
                id: "cached-1",
                artist: "Cached Artist",
                title: "Cached Title",
                storeID: "store_bad_world",
                minutesAgo: 10,
                flags: [.isExclusive],
                reference: now
            ),
        ]
        let cache = InMemoryCacheStore(initial: cached)
        let repository = CachedRadarFeedRepository(cacheStore: cache)

        let releases = try await repository.fetchLatest(forceRefresh: true)
        #expect(releases == cached)
    }

    @Test("returns empty when cache is missing")
    func returnEmptyOnCacheMiss() async throws {
        let repository = CachedRadarFeedRepository(cacheStore: InMemoryCacheStore(initial: nil))
        let releases = try await repository.fetchLatest(forceRefresh: false)
        #expect(releases.isEmpty)
    }
}

private actor InMemoryCacheStore: RadarFeedCacheStore {
    private var stored: [ReleaseDrop]?

    init(initial: [ReleaseDrop]?) {
        stored = initial
    }

    func load() async -> [ReleaseDrop]? {
        stored
    }

    func save(_ releases: [ReleaseDrop]) async {
        stored = releases
    }
}
