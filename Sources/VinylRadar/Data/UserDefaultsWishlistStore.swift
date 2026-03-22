import Foundation

public final class UserDefaultsWishlistStore: WishlistStore {
    private let userDefaults: UserDefaults
    private let key: String

    public init(userDefaults: UserDefaults = .standard, key: String = "savedReleaseIDs") {
        self.userDefaults = userDefaults
        self.key = key
    }

    public func isSaved(id: String) -> Bool {
        savedIDs().contains(id)
    }

    public func toggle(id: String) {
        var ids = savedIDs()
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        userDefaults.set(Array(ids), forKey: key)
    }

    public func savedIDs() -> Set<String> {
        Set(userDefaults.stringArray(forKey: key) ?? [])
    }
}
