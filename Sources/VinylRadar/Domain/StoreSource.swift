import Foundation

public struct StoreSource: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let region: String
    public let isFollowed: Bool

    public init(id: String, name: String, region: String, isFollowed: Bool) {
        self.id = id
        self.name = name
        self.region = region
        self.isFollowed = isFollowed
    }
}
