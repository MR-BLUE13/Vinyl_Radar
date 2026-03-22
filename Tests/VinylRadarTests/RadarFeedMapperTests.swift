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
    }
}
