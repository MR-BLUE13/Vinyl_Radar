import Foundation
import Testing
@testable import VinylRadar

@Suite("RemoteRadarFeedRepositoryTests")
struct RemoteRadarFeedRepositoryTests {
    @Test("fetchLatest decodes snapshot and updates cache")
    func decodeAndCache() async throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let releases = [
            makeRelease(
                id: "remote-1",
                artist: "Remote Artist",
                title: "Remote Title",
                storeID: "store_blood_records",
                minutesAgo: 1,
                flags: [.isNew, .isLimited],
                reference: now
            ),
        ]
        let payload = try makeSnapshotPayload(releases: releases, generatedAt: now)
        let cache = InMemoryRadarFeedCacheStore()

        let repository = try RemoteRadarFeedRepository(
            baseURL: URL(string: "https://api.example.com")!,
            cacheStore: cache,
            fetcher: { request in
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (payload, response)
            }
        )

        let fetched = try await repository.fetchLatest()
        let cached = await cache.load()

        #expect(fetched == releases)
        #expect(cached == releases)
    }

    @Test("fetchLatest falls back to cache on request failure")
    func fallbackToCacheOnFailure() async throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let cachedReleases = [
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

        let cache = InMemoryRadarFeedCacheStore(initial: cachedReleases)
        let repository = try RemoteRadarFeedRepository(
            baseURL: URL(string: "https://api.example.com")!,
            cacheStore: cache,
            fetcher: { _ in
                throw URLError(.cannotConnectToHost)
            }
        )

        let fetched = try await repository.fetchLatest()
        #expect(fetched == cachedReleases)
    }

    @Test("fetchLatest throws when request fails and cache is empty")
    func throwWhenFailureAndNoCache() async throws {
        let cache = InMemoryRadarFeedCacheStore()
        let repository = try RemoteRadarFeedRepository(
            baseURL: URL(string: "https://api.example.com")!,
            cacheStore: cache,
            fetcher: { _ in
                throw URLError(.timedOut)
            }
        )

        await #expect(throws: URLError.self) {
            _ = try await repository.fetchLatest()
        }
    }
}

private struct TestSnapshot: Codable {
    let generatedAt: Date?
    let releases: [ReleaseDrop]
}

private func makeSnapshotPayload(releases: [ReleaseDrop], generatedAt: Date) throws -> Data {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return try encoder.encode(TestSnapshot(generatedAt: generatedAt, releases: releases))
}

private actor InMemoryRadarFeedCacheStore: RadarFeedCacheStore {
    private var stored: [ReleaseDrop]?

    init(initial: [ReleaseDrop]? = nil) {
        stored = initial
    }

    func load() async -> [ReleaseDrop]? {
        stored
    }

    func save(_ releases: [ReleaseDrop]) async {
        stored = releases
    }
}
