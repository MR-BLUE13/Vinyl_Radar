import Foundation

public struct ReleaseDrop: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let artist: String
    public let title: String
    public let coverAssetName: String?
    public let coverImageURL: URL?
    public let sourceItemURL: URL?
    public let sourceItemKey: String
    public let storeID: String
    public let publishedAt: Date
    public let publishedAtSource: PublishedAtSource
    public let flags: ReleaseFlags
    public let description: String?
    public let isSoldOut: Bool
    public let signedByHeuristic: Bool

    public init(
        id: String,
        artist: String,
        title: String,
        coverAssetName: String? = nil,
        storeID: String,
        publishedAt: Date,
        publishedAtSource: PublishedAtSource = .source,
        flags: ReleaseFlags,
        coverImageURL: URL? = nil,
        sourceItemURL: URL? = nil,
        sourceItemKey: String? = nil,
        description: String? = nil,
        isSoldOut: Bool = false,
        signedByHeuristic: Bool = false
    ) {
        self.id = id
        self.artist = artist
        self.title = title
        self.coverAssetName = coverAssetName
        self.coverImageURL = coverImageURL
        self.sourceItemURL = sourceItemURL
        self.sourceItemKey = sourceItemKey ?? id
        self.storeID = storeID
        self.publishedAt = publishedAt
        self.publishedAtSource = publishedAtSource
        self.flags = flags
        self.description = description
        self.isSoldOut = isSoldOut
        self.signedByHeuristic = signedByHeuristic
    }

    enum CodingKeys: String, CodingKey {
        case id
        case artist
        case title
        case coverAssetName
        case coverImageURL
        case sourceItemURL
        case sourceItemKey
        case storeID
        case publishedAt
        case publishedAtSource
        case flags
        case description
        case isSoldOut
        case signedByHeuristic
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        artist = try container.decode(String.self, forKey: .artist)
        title = try container.decode(String.self, forKey: .title)
        coverAssetName = try container.decodeIfPresent(String.self, forKey: .coverAssetName)
        coverImageURL = try container.decodeIfPresent(URL.self, forKey: .coverImageURL)
        sourceItemURL = try container.decodeIfPresent(URL.self, forKey: .sourceItemURL)
        sourceItemKey = try container.decodeIfPresent(String.self, forKey: .sourceItemKey) ?? id
        storeID = try container.decode(String.self, forKey: .storeID)
        publishedAt = try container.decode(Date.self, forKey: .publishedAt)
        publishedAtSource = try container.decodeIfPresent(PublishedAtSource.self, forKey: .publishedAtSource) ?? .unknown
        flags = try container.decode(ReleaseFlags.self, forKey: .flags)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        isSoldOut = try container.decodeIfPresent(Bool.self, forKey: .isSoldOut) ?? false
        signedByHeuristic = try container.decodeIfPresent(Bool.self, forKey: .signedByHeuristic) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(artist, forKey: .artist)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(coverAssetName, forKey: .coverAssetName)
        try container.encodeIfPresent(coverImageURL, forKey: .coverImageURL)
        try container.encodeIfPresent(sourceItemURL, forKey: .sourceItemURL)
        try container.encode(sourceItemKey, forKey: .sourceItemKey)
        try container.encode(storeID, forKey: .storeID)
        try container.encode(publishedAt, forKey: .publishedAt)
        try container.encode(publishedAtSource, forKey: .publishedAtSource)
        try container.encode(flags, forKey: .flags)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(isSoldOut, forKey: .isSoldOut)
        try container.encode(signedByHeuristic, forKey: .signedByHeuristic)
    }
}
