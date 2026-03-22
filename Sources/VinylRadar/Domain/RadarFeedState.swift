import Foundation

public enum RadarFeedState: Equatable, Sendable {
    case loading
    case loaded([RadarFeedItemViewData])
    case empty
    case error(String)
}
