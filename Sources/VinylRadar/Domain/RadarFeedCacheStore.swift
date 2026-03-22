import Foundation

public protocol RadarFeedCacheStore: Sendable {
    func load() async -> [ReleaseDrop]?
    func save(_ releases: [ReleaseDrop]) async
}
