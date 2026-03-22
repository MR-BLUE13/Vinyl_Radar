import Foundation

public protocol RadarFeedRepository: Sendable {
    func fetchLatest() async throws -> [ReleaseDrop]
}
