import Foundation

public struct RadarSummaryData: Equatable, Sendable {
    public let newDropsCount: Int
    public let followedStoreCount: Int
    public let updatedText: String

    public init(newDropsCount: Int, followedStoreCount: Int, updatedText: String) {
        self.newDropsCount = newDropsCount
        self.followedStoreCount = followedStoreCount
        self.updatedText = updatedText
    }

    public var displayText: String {
        "\(newDropsCount) 个新发售 · \(followedStoreCount) 个关注店铺 · \(updatedText)更新"
    }

    public static let placeholder = RadarSummaryData(
        newDropsCount: 0,
        followedStoreCount: 0,
        updatedText: "刚刚"
    )
}
