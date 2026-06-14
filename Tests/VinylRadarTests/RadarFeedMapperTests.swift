import Foundation
import Testing
@testable import VinylRadar

@Suite("RadarFeedMapperTests")
struct RadarFeedMapperTests {
    @Test("maps release + store + saved status")
    func mapFields() {
        let reference = Date(timeIntervalSince1970: 1_700_000_000)
        let releases = [
            makeRelease(
                id: "r1",
                artist: "A",
                title: "T",
                storeID: "s_followed",
                minutesAgo: 5,
                flags: [.isNew, .isLimited],
                description: "Real release description",
                isSoldOut: true,
                reference: reference
            ),
        ]

        let stores = [makeStore(id: "s_followed", followed: true, name: "Needle Lab")]
        let wishlist = InMemoryWishlistStore(ids: ["r1"])
        let mapper = RadarFeedMapper(relativeFormatter: RelativeTimeFormatter())

        let mapped = mapper.map(
            releases: releases,
            stores: stores,
            wishlistStore: wishlist,
            referenceDate: reference
        )

        #expect(mapped.count == 1)
        #expect(mapped[0].sourceName == "Needle Lab")
        #expect(mapped[0].storeID == "s_followed")
        #expect(mapped[0].isSaved)
        #expect(mapped[0].badges == [.new, .limited])
        #expect(mapped[0].publishedAtText == "5分钟前")
        #expect(mapped[0].description == "Real release description")
        #expect(mapped[0].isSoldOut == true)
        #expect(mapped[0].publishedAtSource == .source)
    }

    @Test("first seen published source uses explicit label")
    func firstSeenTimeLabel() {
        let reference = Date(timeIntervalSince1970: 1_700_000_000)
        let releases = [
            makeRelease(
                id: "r1",
                artist: "A",
                title: "T",
                storeID: "s1",
                minutesAgo: 30,
                flags: [.isNew],
                publishedAtSource: .firstSeen,
                reference: reference
            ),
        ]

        let mapper = RadarFeedMapper(relativeFormatter: RelativeTimeFormatter())
        let mapped = mapper.map(
            releases: releases,
            stores: [makeStore(id: "s1", name: "Store 1")],
            wishlistStore: InMemoryWishlistStore(),
            referenceDate: reference
        )

        #expect(mapped.first?.publishedAtText == "首次发现 30分钟前")
    }

    @Test("unknown published source shows unknown label")
    func unknownTimeLabel() {
        let reference = Date(timeIntervalSince1970: 1_700_000_000)
        let releases = [
            makeRelease(
                id: "r1",
                artist: "A",
                title: "T",
                storeID: "s1",
                minutesAgo: 30,
                flags: [.isNew],
                publishedAtSource: .unknown,
                reference: reference
            ),
        ]

        let mapper = RadarFeedMapper(relativeFormatter: RelativeTimeFormatter())
        let mapped = mapper.map(
            releases: releases,
            stores: [makeStore(id: "s1", name: "Store 1")],
            wishlistStore: InMemoryWishlistStore(),
            referenceDate: reference
        )

        #expect(mapped.first?.publishedAtText == "时间未知")
    }

    @Test("signed fallback by title works without signed flag")
    func signedFallbackByTitle() {
        let reference = Date(timeIntervalSince1970: 1_700_000_000)
        let releases = [
            makeRelease(
                id: "r1",
                artist: "A",
                title: "Ambiguous Desire [Personally Signed]",
                storeID: "s1",
                minutesAgo: 10,
                flags: [],
                reference: reference
            ),
        ]

        let mapper = RadarFeedMapper(relativeFormatter: RelativeTimeFormatter())
        let mapped = mapper.map(
            releases: releases,
            stores: [makeStore(id: "s1", name: "Store 1")],
            wishlistStore: InMemoryWishlistStore(),
            referenceDate: reference
        )

        #expect(mapped.first?.isSigned == true)
        #expect(mapped.first?.isSignedDerived == true)
    }

    @Test("blood and bad world map to exclusive even without exclusive flag")
    func exclusiveFallbackByStore() {
        let reference = Date(timeIntervalSince1970: 1_700_000_000)
        let releases = [
            makeRelease(
                id: "r_blood",
                artist: "A",
                title: "Standard Black Pressing",
                storeID: "store_blood_records",
                minutesAgo: 10,
                flags: [],
                reference: reference
            ),
            makeRelease(
                id: "r_badworld",
                artist: "B",
                title: "Standard Black Pressing",
                storeID: "store_bad_world",
                minutesAgo: 9,
                flags: [],
                reference: reference
            ),
        ]

        let mapper = RadarFeedMapper(relativeFormatter: RelativeTimeFormatter())
        let mapped = mapper.map(
            releases: releases,
            stores: [
                makeStore(id: "store_blood_records", name: "Blood Records"),
                makeStore(id: "store_bad_world", name: "bad world"),
            ],
            wishlistStore: InMemoryWishlistStore(),
            referenceDate: reference
        )

        #expect(mapped.count == 2)
        #expect(mapped.allSatisfy { $0.isExclusive })
        #expect(mapped.allSatisfy { $0.badges.contains(.exclusive) })
    }

    @Test("releases with unknown store id are filtered out")
    func filterUnknownStore() {
        let reference = Date(timeIntervalSince1970: 1_700_000_000)
        let releases = [
            makeRelease(
                id: "unknown_store_item",
                artist: "A",
                title: "T",
                storeID: "store_removed_source",
                minutesAgo: 10,
                flags: [.isNew],
                reference: reference
            ),
        ]

        let mapper = RadarFeedMapper(relativeFormatter: RelativeTimeFormatter())
        let mapped = mapper.map(
            releases: releases,
            stores: [makeStore(id: "store_blood_records", name: "Blood Records")],
            wishlistStore: InMemoryWishlistStore(),
            referenceDate: reference
        )

        #expect(mapped.isEmpty)
    }
}
