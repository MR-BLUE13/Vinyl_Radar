import Foundation

public struct RadarRefreshResult: Equatable, Sendable {
    public let didSucceed: Bool
    public let newFeedCount: Int

    public init(didSucceed: Bool, newFeedCount: Int) {
        self.didSucceed = didSucceed
        self.newFeedCount = newFeedCount
    }

    public static let failure = RadarRefreshResult(didSucceed: false, newFeedCount: 0)
    public static let noChange = RadarRefreshResult(didSucceed: true, newFeedCount: 0)

    public var shouldShowToast: Bool {
        didSucceed && newFeedCount > 0
    }
}
