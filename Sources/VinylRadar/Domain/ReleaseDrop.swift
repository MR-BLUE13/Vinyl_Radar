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
    public let flags: ReleaseFlags

    public init(
        id: String,
        artist: String,
        title: String,
        coverAssetName: String? = nil,
        storeID: String,
        publishedAt: Date,
        flags: ReleaseFlags,
        coverImageURL: URL? = nil,
        sourceItemURL: URL? = nil,
        sourceItemKey: String? = nil
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
        self.flags = flags
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
        case flags
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
        flags = try container.decode(ReleaseFlags.self, forKey: .flags)
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
        try container.encode(flags, forKey: .flags)
    }
}
