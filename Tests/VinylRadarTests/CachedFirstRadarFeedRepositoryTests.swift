import Foundation
import Testing
@testable import VinylRadar

@Suite("CachedFirstRadarFeedRepositoryTests")
struct CachedFirstRadarFeedRepositoryTests {
    @Test("returns cache first when not forcing refresh")
    func cacheFirst() async throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let cached = [
            makeRelease(
                id: "cached-first",
                artist: "Cached Artist",
                title: "Cached Title",
                storeID: "store_blood_records",
                minutesAgo: 5,
                flags: [.isNew],
                reference: now
            ),
        ]
        let cacheStore = InMemoryCachedFirstCacheStore(initial: cached)
        let remote = ProbeCachedFirstRepository(releases: [
            makeRelease(
                id: "remote-1",
                artist: "Remote Artist",
                title: "Remote Title",
                storeID: "store_blood_records",
                minutesAgo: 1,
                flags: [.isNew],
                reference: now
            ),
        ])

        let repository = CachedFirstRadarFeedRepository(remote: remote, cacheStore: cacheStore)
        let releases = try await repository.fetchLatest(forceRefresh: false)

        #expect(releases == cached)
        #expect(await remote.recordedForceRefreshValues.isEmpty)
    }

    @Test("cache miss falls back to remote and writes cache")
    func cacheMissFallsBackToRemote() async throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let remoteReleases = [
            makeRelease(
                id: "remote-only",
                artist: "Remote Artist",
                title: "Remote Title",
                storeID: "store_blood_records",
                minutesAgo: 2,
                flags: [.isLimited],
                reference: now
            ),
        ]

        let cacheStore = InMemoryCachedFirstCacheStore(initial: nil)
        let remote = ProbeCachedFirstRepository(releases: remoteReleases)

        let repository = CachedFirstRadarFeedRepository(remote: remote, cacheStore: cacheStore)
        let releases = try await repository.fetchLatest(forceRefresh: false)

        #expect(releases == remoteReleases)
        #expect(await remote.recordedForceRefreshValues == [false])
    }

    @Test("forced refresh always hits remote")
    func forceRefreshHitsRemote() async throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let cached = [
            makeRelease(
                id: "cached-first",
                artist: "Cached Artist",
                title: "Cached Title",
                storeID: "store_blood_records",
                minutesAgo: 5,
                flags: [.isNew],
                reference: now
            ),
        ]
        let remoteReleases = [
            makeRelease(
                id: "remote-forced",
                artist: "Remote Artist",
                title: "Remote Title",
                storeID: "store_bad_world",
                minutesAgo: 1,
                flags: [.isExclusive],
                reference: now
            ),
        ]
        let cacheStore = InMemoryCachedFirstCacheStore(initial: cached)
        let remote = ProbeCachedFirstRepository(releases: remoteReleases)

        let repository = CachedFirstRadarFeedRepository(remote: remote, cacheStore: cacheStore)
        let releases = try await repository.fetchLatest(forceRefresh: true)

        #expect(releases == remoteReleases)
        #expect(await remote.recordedForceRefreshValues == [true])
    }
}

private actor InMemoryCachedFirstCacheStore: RadarFeedCacheStore {
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

private actor ProbeCachedFirstRepository: RadarFeedRepository {
    private let releases: [ReleaseDrop]
    private(set) var recordedForceRefreshValues: [Bool] = []

    init(releases: [ReleaseDrop]) {
        self.releases = releases
    }

    func fetchLatest(forceRefresh: Bool) async throws -> [ReleaseDrop] {
        recordedForceRefreshValues.append(forceRefresh)
        return releases
    }
}
