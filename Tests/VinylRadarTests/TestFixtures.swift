import Foundation
@testable import VinylRadar

func makeStore(id: String, followed: Bool = false, name: String? = nil) -> StoreSource {
    StoreSource(
        id: id,
        name: name ?? "Store \(id)",
        region: "US",
        isFollowed: followed
    )
}

func makeRelease(
    id: String,
    artist: String = "Artist \(UUID().uuidString)",
    title: String = "Title",
    storeID: String = "s1",
    minutesAgo: Int,
    flags: ReleaseFlags = [],
    reference: Date = Date(timeIntervalSince1970: 1_700_000_000)
) -> ReleaseDrop {
    ReleaseDrop(
        id: id,
        artist: artist,
        title: title,
        coverAssetName: "cover_01",
        storeID: storeID,
        publishedAt: reference.addingTimeInterval(TimeInterval(-minutesAgo * 60)),
        flags: flags
    )
}
