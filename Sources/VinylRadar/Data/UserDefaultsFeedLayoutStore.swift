import Foundation

public final class UserDefaultsFeedLayoutStore: FeedLayoutStore {
    private let userDefaults: UserDefaults
    private let key: String

    public init(userDefaults: UserDefaults = .standard, key: String = "feedCardLayout") {
        self.userDefaults = userDefaults
        self.key = key
    }

    public func current() -> FeedCardLayout {
        guard
            let raw = userDefaults.string(forKey: key),
            let layout = FeedCardLayout(rawValue: raw)
        else {
            return .large
        }
        return layout
    }

    public func set(_ layout: FeedCardLayout) {
        userDefaults.set(layout.rawValue, forKey: key)
    }
}
