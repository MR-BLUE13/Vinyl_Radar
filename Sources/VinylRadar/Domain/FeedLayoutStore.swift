import Foundation

public protocol FeedLayoutStore: AnyObject {
    func current() -> FeedCardLayout
    func set(_ layout: FeedCardLayout)
}
