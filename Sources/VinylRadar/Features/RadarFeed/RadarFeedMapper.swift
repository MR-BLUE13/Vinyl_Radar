import Foundation

struct RadarFeedMapper {
    private static let alwaysExclusiveStoreIDs: Set<String> = [
        "store_blood_records",
        "store_bad_world",
    ]

    private static let signedKeywords: [String] = [
        "signed",
        "personally signed",
        "autographed",
        "hand-signed",
        "signature",
        "signed print",
        "签名",
        "亲签",
    ]

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
            .filter { storeMap[$0.storeID] != nil }
            .sorted(by: Self.sortRule)
            .map { release in
                let store = storeMap[release.storeID]
                let relativePublishedText = relativeFormatter.string(since: release.publishedAt, reference: referenceDate)
                let publishedText: String
                switch release.publishedAtSource {
                case .source:
                    publishedText = relativePublishedText
                case .firstSeen:
                    publishedText = "首次发现 \(relativePublishedText)"
                case .unknown:
                    publishedText = "时间未知"
                }

                let signedByFlag = release.flags.contains(.isSigned)
                let signedByText = Self.containsSignedKeyword(in: release.title) || Self.containsSignedKeyword(in: release.description)
                let isSignedDerived = !signedByFlag && (signedByText || release.signedByHeuristic)
                let isSigned = signedByFlag || isSignedDerived
                let isExclusive = release.flags.contains(.isExclusive) || Self.alwaysExclusiveStoreIDs.contains(release.storeID)
                let badges = makeBadges(flags: release.flags, isExclusive: isExclusive)

                return RadarFeedItemViewData(
                    id: release.id,
                    artist: release.artist,
                    title: release.title,
                    coverAssetName: release.coverAssetName,
                    coverImageURL: release.coverImageURL,
                    sourceItemURL: release.sourceItemURL,
                    storeID: release.storeID,
                    sourceName: store?.name ?? "未知店铺",
                    publishedAtText: publishedText,
                    publishedAt: release.publishedAt,
                    badges: badges,
                    publishedAtSource: release.publishedAtSource,
                    isExclusive: isExclusive,
                    isSigned: isSigned,
                    isSignedDerived: isSignedDerived,
                    isSaved: wishlistStore.isSaved(id: release.id),
                    description: release.description,
                    isSoldOut: release.isSoldOut
                )
            }
    }

    func apply(
        quickFilter: RadarQuickFilter,
        stockFilter: StockAvailabilityFilter,
        selectedStoreIDs: Set<String>,
        to items: [RadarFeedItemViewData]
    ) -> [RadarFeedItemViewData] {
        let byQuickFilter = applyQuickFilter(quickFilter, to: items)

        let byStockFilter: [RadarFeedItemViewData]
        switch stockFilter {
        case .all:
            byStockFilter = byQuickFilter
        case .inStock:
            byStockFilter = byQuickFilter.filter { !$0.isSoldOut }
        }

        guard !selectedStoreIDs.isEmpty else {
            return byStockFilter
        }

        return byStockFilter.filter { selectedStoreIDs.contains($0.storeID) }
    }

    func storeFilterOptions(
        from items: [RadarFeedItemViewData],
        stores: [StoreSource],
        selectedStoreIDs: Set<String>,
        quickFilter: RadarQuickFilter,
        stockFilter: StockAvailabilityFilter
    ) -> [StoreFilterOption] {
        let byQuickFilter = applyQuickFilter(quickFilter, to: items)
        let totalCountByStore = Dictionary(grouping: byQuickFilter, by: \.storeID).mapValues(\.count)
        let inStockCountByStore = Dictionary(
            grouping: byQuickFilter.filter { !$0.isSoldOut },
            by: \.storeID
        ).mapValues(\.count)

        return stores
            .map { store in
                let isStoreSelected = selectedStoreIDs.isEmpty || selectedStoreIDs.contains(store.id)
                return StoreFilterOption(
                    id: store.id,
                    name: store.name,
                    totalCount: totalCountByStore[store.id, default: 0],
                    inStockCount: inStockCountByStore[store.id, default: 0],
                    isSelected: isStoreSelected
                )
            }
            .sorted { lhs, rhs in
                let lhsCount = lhs.displayCount(for: stockFilter)
                let rhsCount = rhs.displayCount(for: stockFilter)
                if lhsCount != rhsCount {
                    return lhsCount > rhsCount
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

    private func applyQuickFilter(
        _ quickFilter: RadarQuickFilter,
        to items: [RadarFeedItemViewData]
    ) -> [RadarFeedItemViewData] {
        switch quickFilter {
        case .all:
            return items
        case .exclusive:
            return items.filter { $0.isExclusive }
        case .signed:
            return items.filter { $0.isSigned }
        case .saved:
            return items.filter { $0.isSaved }
        }
    }

    private func makeBadges(flags: ReleaseFlags, isExclusive: Bool) -> [RadarBadge] {
        var result: [RadarBadge] = []

        if flags.contains(.isNew) {
            result.append(.new)
        }
        if isExclusive {
            result.append(.exclusive)
        }
        if flags.contains(.isLimited) {
            result.append(.limited)
        }
        return result
    }

    private static func containsSignedKeyword(in value: String?) -> Bool {
        guard let value else { return false }
        let normalized = value.lowercased().replacingOccurrences(of: "unsigned", with: "")
        return signedKeywords.contains { normalized.contains($0) }
    }
}
