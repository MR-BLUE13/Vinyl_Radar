import Foundation

public actor FallbackRadarFeedRepository: RadarFeedRepository {
    private let primary: any RadarFeedRepository
    private let fallback: any RadarFeedRepository

    public init(primary: any RadarFeedRepository, fallback: any RadarFeedRepository) {
        self.primary = primary
        self.fallback = fallback
    }

    public func fetchLatest() async throws -> [ReleaseDrop] {
        do {
            let primaryResult = try await primary.fetchLatest()
            if primaryResult.isEmpty {
                return try await fallback.fetchLatest()
            }
            return primaryResult
        } catch {
            return try await fallback.fetchLatest()
        }
    }
}
