import Foundation
import Testing
@testable import VinylRadar

@Suite("FeedLayoutStoreTests")
struct FeedLayoutStoreTests {
    @Test("defaults to large when no persisted value")
    func defaultLayout() {
        let suiteName = "FeedLayoutStoreTests.default.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsFeedLayoutStore(userDefaults: defaults, key: "feedCardLayout")
        #expect(store.current() == .large)
    }

    @Test("persists selected layout")
    func persistLayout() {
        let suiteName = "FeedLayoutStoreTests.persist.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsFeedLayoutStore(userDefaults: defaults, key: "feedCardLayout")
        store.set(.compact)

        let reloaded = UserDefaultsFeedLayoutStore(userDefaults: defaults, key: "feedCardLayout")
        #expect(reloaded.current() == .compact)
    }
}
