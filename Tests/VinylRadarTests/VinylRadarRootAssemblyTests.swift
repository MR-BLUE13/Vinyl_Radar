import Foundation
import Testing
@testable import VinylRadar

@Suite("VinylRadarRootAssemblyTests")
struct VinylRadarRootAssemblyTests {
    @Test("default stores exclude rough trade")
    func defaultStoresExcludeRoughTrade() {
        let stores = MockBootstrap.defaultStores()
        #expect(stores.contains(where: { $0.id == "store_rough_trade_us" }) == false)
    }

    @Test("without api URL default repository reads from cache and does not use mock")
    func noURLUsesCachedRepository() async throws {
        let reference = Date(timeIntervalSince1970: 1_700_000_000)
        let cachedReleases = [
            makeRelease(
                id: "cached-assembly-1",
                artist: "Cached Artist",
                title: "Cached Title",
                storeID: "store_blood_records",
                minutesAgo: 5,
                flags: [.isNew],
                reference: reference
            ),
        ]
        let cacheStore = InMemoryRootCacheStore(initial: cachedReleases)
        let repository = VinylRadarRootView.makeDefaultRepository(
            apiBaseURL: nil,
            cacheStore: cacheStore
        )

        let releases = try await repository.fetchLatest(forceRefresh: false)
        #expect(releases == cachedReleases)
    }
}

private actor InMemoryRootCacheStore: RadarFeedCacheStore {
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
