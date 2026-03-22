import Foundation
import Testing
@testable import VinylRadar

@Suite("FeedSnapshotDedupeTests")
struct FeedSnapshotDedupeTests {
    @Test("dedupes within same store by sourceItemKey and keeps newer one")
    func dedupeWithinStore() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let older = ReleaseDrop(
            id: "blood-old",
            artist: "Artist",
            title: "Title",
            coverAssetName: "cover_01",
            storeID: "store_blood_records",
            publishedAt: now.addingTimeInterval(-600),
            flags: [.isLimited],
            sourceItemKey: "blood_123"
        )

        let newer = ReleaseDrop(
            id: "blood-new",
            artist: "Artist",
            title: "Title",
            coverAssetName: "cover_01",
            storeID: "store_blood_records",
            publishedAt: now.addingTimeInterval(-60),
            flags: [.isLimited],
            sourceItemKey: "blood_123"
        )

        let otherStoreSameKey = ReleaseDrop(
            id: "bad-world-1",
            artist: "Artist",
            title: "Title",
            coverAssetName: "cover_02",
            storeID: "store_bad_world",
            publishedAt: now.addingTimeInterval(-120),
            flags: [.isLimited],
            sourceItemKey: "blood_123"
        )

        let result = FeedSnapshotDedupe.dedupeWithinStore([older, newer, otherStoreSameKey])
        let ids = Set(result.map(\.id))

        #expect(ids.contains("blood-new"))
        #expect(!ids.contains("blood-old"))
        #expect(ids.contains("bad-world-1"))
        #expect(result.count == 2)
    }
}
