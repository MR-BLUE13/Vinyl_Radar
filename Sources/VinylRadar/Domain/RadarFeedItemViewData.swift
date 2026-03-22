import Foundation

public struct RadarFeedItemViewData: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let artist: String
    public let title: String
    public let coverAssetName: String?
    public let coverImageURL: URL?
    public let sourceItemURL: URL?
    public let storeID: String
    public let sourceName: String
    public let publishedAtText: String
    public let publishedAt: Date
    public let badges: [RadarBadge]
    public let isSaved: Bool

    public init(
        id: String,
        artist: String,
        title: String,
        coverAssetName: String? = nil,
        coverImageURL: URL? = nil,
        sourceItemURL: URL? = nil,
        storeID: String,
        sourceName: String,
        publishedAtText: String,
        publishedAt: Date,
        badges: [RadarBadge],
        isSaved: Bool
    ) {
        self.id = id
        self.artist = artist
        self.title = title
        self.coverAssetName = coverAssetName
        self.coverImageURL = coverImageURL
        self.sourceItemURL = sourceItemURL
        self.storeID = storeID
        self.sourceName = sourceName
        self.publishedAtText = publishedAtText
        self.publishedAt = publishedAt
        self.badges = badges
        self.isSaved = isSaved
    }
}
