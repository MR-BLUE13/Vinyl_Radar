import Foundation

public protocol WishlistStore: AnyObject {
    func isSaved(id: String) -> Bool
    func toggle(id: String)
    func savedIDs() -> Set<String>
}
