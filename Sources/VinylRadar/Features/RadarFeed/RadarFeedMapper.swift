import Foundation

struct RadarFeedMapper {
    private let relativeFormatter: RelativeTimeFormatter

    init(relativeFormatter: RelativeTimeFormatter = RelativeTimeFormatter()) {
        self.relativeFormatter = relativeFormatter
    }

    func map(
        releases: [ReleaseDrop],
        stores: [StoreSource],
        wishlistStore: WishlistStore,
        referenceDate: Date
    ) -> [RadarFeedItemViewData] {
        let storeMap = Dictionary(uniqueKeysWithValues: stores.map { ($0.id, $0) })

        return releases
            .sorted(by: Self.sortRule)
            .map { release in
                let store = storeMap[release.storeID]
                return RadarFeedItemViewData(
                    id: release.id,
                    artist: release.artist,
                    title: release.title,
                    coverAssetName: release.coverAssetName,
                    coverImageURL: release.coverImageURL,
                    sourceItemURL: release.sourceItemURL,
                    storeID: release.storeID,
                    sourceName: store?.name ?? "未知店铺",
                    publishedAtText: relativeFormatter.string(since: release.publishedAt, reference: referenceDate),
                    publishedAt: release.publishedAt,
                    badges: release.flags.badges,
                    isSaved: wishlistStore.isSaved(id: release.id)
                )
            }
    }

    func apply(
        quickFilter: RadarQuickFilter,
        selectedStoreIDs: Set<String>,
        to items: [RadarFeedItemViewData]
    ) -> [RadarFeedItemViewData] {
        let byQuickFilter: [RadarFeedItemViewData]
        switch quickFilter {
        case .all:
            byQuickFilter = items
        case .limited:
            byQuickFilter = items.filter { $0.badges.contains(.limited) }
        case .colored:
            byQuickFilter = items.filter { $0.badges.contains(.colored) }
        case .exclusive:
            byQuickFilter = items.filter { $0.badges.contains(.exclusive) }
        case .saved:
            byQuickFilter = items.filter { $0.isSaved }
        }

        guard !selectedStoreIDs.isEmpty else {
            return byQuickFilter
        }

        return byQuickFilter.filter { selectedStoreIDs.contains($0.storeID) }
    }

    func storeFilterOptions(
        from items: [RadarFeedItemViewData],
        stores: [StoreSource],
        selectedStoreIDs: Set<String>
    ) -> [StoreFilterOption] {
        let countByStore = Dictionary(grouping: items, by: \.storeID).mapValues(\.count)

        return stores
            .map { store in
                StoreFilterOption(
                    id: store.id,
                    name: store.name,
                    count: countByStore[store.id, default: 0],
                    isSelected: selectedStoreIDs.contains(store.id)
                )
            }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count {
                    return lhs.count > rhs.count
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    func summary(
        releases: [ReleaseDrop],
        stores: [StoreSource],
        updatedAt: Date,
        referenceDate: Date
    ) -> RadarSummaryData {
        let newDropsCount = releases.filter { $0.flags.contains(.isNew) }.count
        let releaseStoreIDs = Set(releases.map(\.storeID))
        let followedStoreCount = stores.filter { $0.isFollowed && releaseStoreIDs.contains($0.id) }.count
        let updatedText = relativeFormatter.string(since: updatedAt, reference: referenceDate)

        return RadarSummaryData(
            newDropsCount: newDropsCount,
            followedStoreCount: followedStoreCount,
            updatedText: updatedText
        )
    }

    static func sortRule(lhs: ReleaseDrop, rhs: ReleaseDrop) -> Bool {
        if lhs.publishedAt != rhs.publishedAt {
            return lhs.publishedAt > rhs.publishedAt
        }

        if lhs.flags.rarityScore != rhs.flags.rarityScore {
            return lhs.flags.rarityScore > rhs.flags.rarityScore
        }

        if lhs.artist != rhs.artist {
            return lhs.artist.localizedCaseInsensitiveCompare(rhs.artist) == .orderedAscending
        }

        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }
}
