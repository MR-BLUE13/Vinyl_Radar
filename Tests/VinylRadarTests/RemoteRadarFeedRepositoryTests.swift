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
                description: "Remote description copy",
                isSoldOut: true,
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
        #expect(fetched.first?.description == "Remote description copy")
        #expect(fetched.first?.isSoldOut == true)
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

    @Test("force refresh appends refresh query parameter")
    func forceRefreshAddsQueryItem() async throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let releases = [
            makeRelease(
                id: "remote-force",
                artist: "Remote Artist",
                title: "Remote Title",
                storeID: "store_blood_records",
                minutesAgo: 1,
                flags: [.isNew],
                reference: now
            ),
        ]
        let payload = try makeSnapshotPayload(releases: releases, generatedAt: now)
        let cache = InMemoryRadarFeedCacheStore()
        let recorder = RequestRecorder()

        let repository = try RemoteRadarFeedRepository(
            baseURL: URL(string: "https://api.example.com")!,
            cacheStore: cache,
            fetcher: { request in
                await recorder.record(url: request.url)
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (payload, response)
            }
        )

        _ = try await repository.fetchLatest(forceRefresh: true)
        let requestedURL = await recorder.lastURL
        let queryItems = URLComponents(url: requestedURL!, resolvingAgainstBaseURL: false)?.queryItems

        #expect(queryItems?.contains(where: { $0.name == "refresh" && $0.value == "1" }) == true)
    }

    @Test("force refresh failure falls back to non-refresh endpoint")
    func forceRefreshFallsBackToSnapshotEndpoint() async throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let releases = [
            makeRelease(
                id: "remote-fallback-1",
                artist: "Remote Artist",
                title: "Remote Title",
                storeID: "store_blood_records",
                minutesAgo: 2,
                flags: [.isNew],
                reference: now
            ),
        ]
        let payload = try makeSnapshotPayload(releases: releases, generatedAt: now)
        let cache = InMemoryRadarFeedCacheStore()
        let recorder = RequestRecorder()

        let repository = try RemoteRadarFeedRepository(
            baseURL: URL(string: "https://api.example.com")!,
            cacheStore: cache,
            fetcher: { request in
                await recorder.record(url: request.url)
                if request.url?.absoluteString.contains("refresh=1") == true {
                    throw URLError(.timedOut)
                }
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (payload, response)
            }
        )

        let fetched = try await repository.fetchLatest(forceRefresh: true)
        let requestedURLs = await recorder.urls

        #expect(fetched == releases)
        #expect(requestedURLs.count == 2)
        #expect(requestedURLs[0].absoluteString.contains("refresh=1"))
        #expect(!requestedURLs[1].absoluteString.contains("refresh=1"))
    }

    @Test("force refresh and snapshot failure falls back to cache")
    func forceRefreshAndSnapshotFailureUsesCache() async throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let cachedReleases = [
            makeRelease(
                id: "cached-fallback-1",
                artist: "Cached Artist",
                title: "Cached Title",
                storeID: "store_bad_world",
                minutesAgo: 5,
                flags: [.isExclusive],
                reference: now
            ),
        ]
        let cache = InMemoryRadarFeedCacheStore(initial: cachedReleases)
        let recorder = RequestRecorder()

        let repository = try RemoteRadarFeedRepository(
            baseURL: URL(string: "https://api.example.com")!,
            cacheStore: cache,
            fetcher: { request in
                await recorder.record(url: request.url)
                throw URLError(.cannotConnectToHost)
            }
        )

        let fetched = try await repository.fetchLatest(forceRefresh: true)
        let requestedURLs = await recorder.urls

        #expect(fetched == cachedReleases)
        #expect(requestedURLs.count == 2)
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

private actor RequestRecorder {
    private(set) var urls: [URL] = []
    private(set) var lastURL: URL?

    func record(url: URL?) {
        lastURL = url
        if let url {
            urls.append(url)
        }
    }
}
