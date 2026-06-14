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
    public let publishedAtSource: PublishedAtSource
    public let badges: [RadarBadge]
    public let isExclusive: Bool
    public let isSigned: Bool
    public let isSignedDerived: Bool
    public let isSaved: Bool
    public let description: String?
    public let isSoldOut: Bool

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
        publishedAtSource: PublishedAtSource = .unknown,
        isExclusive: Bool = false,
        isSigned: Bool = false,
        isSignedDerived: Bool = false,
        isSaved: Bool,
        description: String? = nil,
        isSoldOut: Bool = false
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
        self.publishedAtSource = publishedAtSource
        self.badges = badges
        self.isExclusive = isExclusive
        self.isSigned = isSigned
        self.isSignedDerived = isSignedDerived
        self.isSaved = isSaved
        self.description = description
        self.isSoldOut = isSoldOut
    }
}
