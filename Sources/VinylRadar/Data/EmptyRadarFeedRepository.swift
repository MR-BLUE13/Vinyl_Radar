import Foundation

public actor EmptyRadarFeedRepository: RadarFeedRepository {
    public init() {}

    public func fetchLatest(forceRefresh: Bool = false) async throws -> [ReleaseDrop] {
        []
    }
}
