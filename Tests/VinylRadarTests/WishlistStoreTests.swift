import Foundation
import Testing
@testable import VinylRadar

@Suite("WishlistStoreTests")
struct WishlistStoreTests {
    @Test("toggle persists IDs in UserDefaults")
    func togglePersists() {
        let suiteName = "WishlistStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = UserDefaultsWishlistStore(userDefaults: defaults, key: "savedReleaseIDs")

        #expect(store.savedIDs().isEmpty)

        store.toggle(id: "r-1")
        #expect(store.isSaved(id: "r-1"))
        #expect(store.savedIDs() == ["r-1"])

        let reloadedStore = UserDefaultsWishlistStore(userDefaults: defaults, key: "savedReleaseIDs")
        #expect(reloadedStore.isSaved(id: "r-1"))

        reloadedStore.toggle(id: "r-1")
        #expect(!reloadedStore.isSaved(id: "r-1"))
    }
}
