import Foundation

public enum MockBootstrap {
    public static func defaultStores() -> [StoreSource] {
        (try? MockDataLoader.loadStores()) ?? []
    }
}
