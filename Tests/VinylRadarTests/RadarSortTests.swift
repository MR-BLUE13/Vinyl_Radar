import Foundation
import Testing
@testable import VinylRadar

@Suite("RadarSortTests")
struct RadarSortTests {
    @Test("newer release comes first")
    func sortByPublishedDate() {
        let reference = Date(timeIntervalSince1970: 1_700_000_000)
        let old = makeRelease(id: "old", minutesAgo: 60, reference: reference)
        let fresh = makeRelease(id: "fresh", minutesAgo: 5, reference: reference)

        let sorted = [old, fresh].sorted(by: RadarFeedMapper.sortRule)
        #expect(sorted.map { $0.id } == ["fresh", "old"])
    }

    @Test("same timestamp uses rarity priority")
    func sortByRarityForSameTimestamp() {
        let reference = Date(timeIntervalSince1970: 1_700_000_000)
        let sameTime = reference.addingTimeInterval(-300)

        let limited = ReleaseDrop(
            id: "limited",
            artist: "A",
            title: "T1",
            coverAssetName: "cover_01",
            storeID: "s1",
            publishedAt: sameTime,
            flags: [.isLimited]
        )

        let exclusive = ReleaseDrop(
            id: "exclusive",
            artist: "B",
            title: "T2",
            coverAssetName: "cover_02",
            storeID: "s1",
            publishedAt: sameTime,
            flags: [.isExclusive]
        )

        let sorted = [limited, exclusive].sorted(by: RadarFeedMapper.sortRule)
        #expect(sorted.map { $0.id } == ["exclusive", "limited"])
    }
}
