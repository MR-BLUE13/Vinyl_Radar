import Foundation

public actor UserDefaultsRadarFeedCacheStore: RadarFeedCacheStore {
    private let defaults: UserDefaults
    private let key: String

    public init(
        defaults: UserDefaults = .standard,
        key: String = "feed.cache.releases.v1"
    ) {
        self.defaults = defaults
        self.key = key
    }

    public func load() async -> [ReleaseDrop]? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([ReleaseDrop].self, from: data)
    }

    public func save(_ releases: [ReleaseDrop]) async {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(releases) else {
            return
        }

        defaults.set(data, forKey: key)
    }
}
