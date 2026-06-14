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
                isSigned: true,
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
                isExclusive: true,
                isSaved: true
            ),
        ]
    }

    @Test("quick filter order excludes colored")
    func quickFilterOrder() {
        #expect(RadarQuickFilter.allCases == [.all, .exclusive, .signed, .saved])
    }

    @Test("all filter keeps all items")
    func allFilter() {
        #expect(mapper.apply(quickFilter: .all, stockFilter: .all, selectedStoreIDs: [], to: items).count == 3)
    }

    @Test("signed filter")
    func signedFilter() {
        let result = mapper.apply(quickFilter: .signed, stockFilter: .all, selectedStoreIDs: [], to: items)
        #expect(result.map { $0.id } == ["b"])
    }

    @Test("signed filter can include derived signed item")
    func signedDerivedFilter() {
        let derivedItems = [
            RadarFeedItemViewData(
                id: "d",
                artist: "Artist D",
                title: "Release [Personally Signed]",
                coverAssetName: "cover_04",
                storeID: "s1",
                sourceName: "S1",
                publishedAtText: "刚刚",
                publishedAt: .now,
                badges: [],
                isSigned: true,
                isSignedDerived: true,
                isSaved: false
            ),
        ]

        let result = mapper.apply(quickFilter: .signed, stockFilter: .all, selectedStoreIDs: [], to: derivedItems)
        #expect(result.map { $0.id } == ["d"])
    }

    @Test("exclusive filter")
    func exclusiveFilter() {
        let result = mapper.apply(quickFilter: .exclusive, stockFilter: .all, selectedStoreIDs: [], to: items)
        #expect(result.map { $0.id } == ["c"])
    }

    @Test("saved filter")
    func savedFilter() {
        let result = mapper.apply(quickFilter: .saved, stockFilter: .all, selectedStoreIDs: [], to: items)
        #expect(result.map { $0.id } == ["a", "c"])
    }

    @Test("quick filter and store filter are AND")
    func quickAndStoreFilter() {
        let result = mapper.apply(quickFilter: .saved, stockFilter: .all, selectedStoreIDs: ["s2"], to: items)
        #expect(result.map { $0.id } == ["c"])
    }

    @Test("stock inStock filter excludes sold out items")
    func inStockFilter() {
        let soldOutItems = [
            items[0],
            RadarFeedItemViewData(
                id: "d",
                artist: "Artist D",
                title: "D",
                coverAssetName: "cover_04",
                storeID: "s1",
                sourceName: "S1",
                publishedAtText: "刚刚",
                publishedAt: .now,
                badges: [.new],
                isSaved: false,
                isSoldOut: true
            ),
        ]
        let result = mapper.apply(quickFilter: .all, stockFilter: .inStock, selectedStoreIDs: [], to: soldOutItems)
        #expect(result.map { $0.id } == ["a"])
    }

    @Test("store filter option count switches between all and inStock")
    func storeFilterOptionCountByStockFilter() {
        let mixed = [
            items[0],
            items[1],
            RadarFeedItemViewData(
                id: "d",
                artist: "Artist D",
                title: "D",
                coverAssetName: "cover_04",
                storeID: "s2",
                sourceName: "S2",
                publishedAtText: "刚刚",
                publishedAt: .now,
                badges: [.limited],
                isSaved: false,
                isSoldOut: true
            ),
        ]
        let stores = [
            makeStore(id: "s1", name: "Store 1"),
            makeStore(id: "s2", name: "Store 2"),
        ]

        let allOptions = mapper.storeFilterOptions(
            from: mixed,
            stores: stores,
            selectedStoreIDs: [],
            quickFilter: .all,
            stockFilter: .all
        )
        let inStockOptions = mapper.storeFilterOptions(
            from: mixed,
            stores: stores,
            selectedStoreIDs: [],
            quickFilter: .all,
            stockFilter: .inStock
        )

        let s2All = allOptions.first(where: { $0.id == "s2" })
        let s2InStock = inStockOptions.first(where: { $0.id == "s2" })
        #expect(s2All?.displayCount(for: .all) == 2)
        #expect(s2InStock?.displayCount(for: .inStock) == 1)
        #expect(allOptions.filter { !$0.isSelected }.isEmpty)
    }
}
