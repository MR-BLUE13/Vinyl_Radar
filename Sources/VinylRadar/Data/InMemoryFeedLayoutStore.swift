import Foundation

public final class InMemoryFeedLayoutStore: FeedLayoutStore {
    private var layout: FeedCardLayout

    public init(layout: FeedCardLayout = .large) {
        self.layout = layout
    }

    public func current() -> FeedCardLayout {
        layout
    }

    public func set(_ layout: FeedCardLayout) {
        self.layout = layout
    }
}
