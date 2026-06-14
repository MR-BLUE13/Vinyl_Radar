import Foundation
import Testing
@testable import VinylRadar

@Suite("FallbackRadarFeedRepositoryTests")
struct FallbackRadarFeedRepositoryTests {
    @Test("returns primary result even when empty")
    func keepPrimaryEmptyResult() async throws {
        let primary = StubRadarFeedRepository(result: .success([]))
        let fallback = StubRadarFeedRepository(
            result: .success([
                makeRelease(id: "fallback-1", minutesAgo: 1),
            ])
        )

        let repository = FallbackRadarFeedRepository(primary: primary, fallback: fallback)
        let releases = try await repository.fetchLatest(forceRefresh: true)

        #expect(releases.isEmpty)
        #expect(await fallback.callCount == 0)
        #expect(await primary.receivedForceRefresh == [true])
    }

    @Test("falls back when primary throws")
    func fallbackOnError() async throws {
        let primary = StubRadarFeedRepository(result: .failure(MockRadarFeedRepositoryError.forcedFailure))
        let expected = [
            makeRelease(id: "fallback-1", minutesAgo: 1),
        ]
        let fallback = StubRadarFeedRepository(result: .success(expected))

        let repository = FallbackRadarFeedRepository(primary: primary, fallback: fallback)
        let releases = try await repository.fetchLatest(forceRefresh: false)

        #expect(releases == expected)
        #expect(await fallback.callCount == 1)
        #expect(await fallback.receivedForceRefresh == [false])
    }
}

private actor StubRadarFeedRepository: RadarFeedRepository {
    enum Result {
        case success([ReleaseDrop])
        case failure(Error)
    }

    private let result: Result
    private(set) var callCount: Int = 0
    private(set) var receivedForceRefresh: [Bool] = []

    init(result: Result) {
        self.result = result
    }

    func fetchLatest(forceRefresh: Bool) async throws -> [ReleaseDrop] {
        callCount += 1
        receivedForceRefresh.append(forceRefresh)
        switch result {
        case .success(let releases):
            return releases
        case .failure(let error):
            throw error
        }
    }
}
