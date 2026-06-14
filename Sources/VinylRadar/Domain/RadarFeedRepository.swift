import Foundation

public protocol RadarFeedRepository: Sendable {
    func fetchLatest(forceRefresh: Bool) async throws -> [ReleaseDrop]
}

public extension RadarFeedRepository {
    func fetchLatest() async throws -> [ReleaseDrop] {
        try await fetchLatest(forceRefresh: false)
    }
}
