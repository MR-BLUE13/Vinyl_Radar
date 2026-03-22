import Foundation

public final class InMemoryWishlistStore: WishlistStore {
    private var ids: Set<String>

    public init(ids: Set<String> = []) {
        self.ids = ids
    }

    public func isSaved(id: String) -> Bool {
        ids.contains(id)
    }

    public func toggle(id: String) {
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
    }

    public func savedIDs() -> Set<String> {
        ids
    }
}
