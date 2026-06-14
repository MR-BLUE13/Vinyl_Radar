import Foundation

public actor FallbackRadarFeedRepository: RadarFeedRepository {
    private let primary: any RadarFeedRepository
    private let fallback: any RadarFeedRepository

    public init(primary: any RadarFeedRepository, fallback: any RadarFeedRepository) {
        self.primary = primary
        self.fallback = fallback
    }

    public func fetchLatest(forceRefresh: Bool = false) async throws -> [ReleaseDrop] {
        do {
            return try await primary.fetchLatest(forceRefresh: forceRefresh)
        } catch {
            return try await fallback.fetchLatest(forceRefresh: forceRefresh)
        }
    }
}
