import Foundation

public enum MockRadarFeedRepositoryMode: Sendable {
    case resources
    case custom([ReleaseDrop])
    case empty
    case failure
}

public enum MockRadarFeedRepositoryError: Error, Equatable {
    case forcedFailure
}

public actor MockRadarFeedRepository: RadarFeedRepository {
    private let mode: MockRadarFeedRepositoryMode

    public init(mode: MockRadarFeedRepositoryMode = .resources) {
        self.mode = mode
    }

    public func fetchLatest() async throws -> [ReleaseDrop] {
        switch mode {
        case .resources:
            return try MockDataLoader.loadReleases()
        case .custom(let releases):
            return releases
        case .empty:
            return []
        case .failure:
            throw MockRadarFeedRepositoryError.forcedFailure
        }
    }

}
