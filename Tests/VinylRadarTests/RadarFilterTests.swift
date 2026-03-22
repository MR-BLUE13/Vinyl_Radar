import Foundation
import Testing
@testable import VinylRadar

@Suite("RadarQuickFilterTests")
struct RadarQuickFilterTests {
    private let mapper = RadarFeedMapper()

    private var items: [RadarFeedItemViewData] {
        [
            .init(
                id: "a",
                artist: "Artist A",
                title: "A",
                coverAssetName: "cover_01",
                storeID: "s1",
                sourceName: "S1",
                publishedAtText: "刚刚",
                publishedAt: .now,
                badges: [.new],
                isSaved: true
            ),
            .init(
                id: "b",
                artist: "Artist B",
                title: "B",
                coverAssetName: "cover_02",
                storeID: "s2",
                sourceName: "S2",
                publishedAtText: "刚刚",
                publishedAt: .now,
                badges: [.limited, .colored],
                isSaved: false
            ),
            .init(
                id: "c",
                artist: "Artist C",
                title: "C",
                coverAssetName: "cover_03",
                storeID: "s2",
                sourceName: "S3",
                publishedAtText: "刚刚",
                publishedAt: .now,
                badges: [.exclusive],
                isSaved: true
            ),
        ]
    }

    @Test("all filter keeps all items")
    func allFilter() {
        #expect(mapper.apply(quickFilter: .all, selectedStoreIDs: [], to: items).count == 3)
    }

    @Test("limited filter")
    func limitedFilter() {
        let result = mapper.apply(quickFilter: .limited, selectedStoreIDs: [], to: items)
        #expect(result.map { $0.id } == ["b"])
    }

    @Test("colored filter")
    func coloredFilter() {
        let result = mapper.apply(quickFilter: .colored, selectedStoreIDs: [], to: items)
        #expect(result.map { $0.id } == ["b"])
    }

    @Test("exclusive filter")
    func exclusiveFilter() {
        let result = mapper.apply(quickFilter: .exclusive, selectedStoreIDs: [], to: items)
        #expect(result.map { $0.id } == ["c"])
    }

    @Test("saved filter")
    func savedFilter() {
        let result = mapper.apply(quickFilter: .saved, selectedStoreIDs: [], to: items)
        #expect(result.map { $0.id } == ["a", "c"])
    }

    @Test("quick filter and store filter are AND")
    func quickAndStoreFilter() {
        let result = mapper.apply(quickFilter: .saved, selectedStoreIDs: ["s2"], to: items)
        #expect(result.map { $0.id } == ["c"])
    }
}
