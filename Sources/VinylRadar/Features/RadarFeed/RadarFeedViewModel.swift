import Foundation

@MainActor
public final class RadarFeedViewModel: ObservableObject {
    @Published public private(set) var state: RadarFeedState = .loading
    @Published public var cardLayout: FeedCardLayout
    @Published public var selectedQuickFilter: RadarQuickFilter = .all {
        didSet {
            applyCurrentFilters()
        }
    }
    @Published public var selectedStoreIDs: Set<String> = [] {
        didSet {
            applyCurrentFilters()
            refreshStoreFilterOptions()
        }
    }
    @Published public var isStoreFilterSheetPresented = false
    @Published public private(set) var summaryData: RadarSummaryData = .placeholder
    @Published private(set) var storeFilterOptions: [StoreFilterOption] = []

    private let repository: any RadarFeedRepository
    private let stores: [StoreSource]
    private let wishlistStore: WishlistStore
    private let layoutStore: FeedLayoutStore
    private let mapper: RadarFeedMapper
    private let now: () -> Date
    private let loadDelayNanoseconds: UInt64

    private var hasLoadedAtLeastOnce = false
    private var allReleases: [ReleaseDrop] = []
    private var allItems: [RadarFeedItemViewData] = []
    private var lastUpdatedAt: Date?
    private var seenReleaseIDs: Set<String> = []

    public init(
        repository: any RadarFeedRepository,
        stores: [StoreSource],
        wishlistStore: WishlistStore,
        layoutStore: FeedLayoutStore,
        now: @escaping () -> Date = Date.init,
        loadDelayNanoseconds: UInt64 = 600_000_000
    ) {
        self.repository = repository
        self.stores = stores
        self.wishlistStore = wishlistStore
        self.layoutStore = layoutStore
        self.mapper = RadarFeedMapper()
        self.now = now
        self.loadDelayNanoseconds = loadDelayNanoseconds
        self.cardLayout = layoutStore.current()
    }

    public func loadIfNeeded() async {
        guard !hasLoadedAtLeastOnce else { return }
        await load()
    }

    public func load() async {
        hasLoadedAtLeastOnce = true
        _ = await performLoad(
            countNewItems: false,
            showLoadingState: true,
            preserveStateOnFailure: false
        )
    }

    @discardableResult
    public func retry() async -> RadarRefreshResult {
        await performLoad(
            countNewItems: true,
            showLoadingState: false,
            preserveStateOnFailure: true
        )
    }

    public func toggleCardLayout() {
        let next: FeedCardLayout = cardLayout == .large ? .compact : .large
        cardLayout = next
        layoutStore.set(next)
    }

    public func presentStoreFilterSheet() {
        isStoreFilterSheetPresented = true
    }

    public func dismissStoreFilterSheet() {
        isStoreFilterSheetPresented = false
    }

    public func applyStoreSelection(_ storeIDs: Set<String>) {
        selectedStoreIDs = storeIDs
        dismissStoreFilterSheet()
    }

    public func toggleSaved(id: String) {
        wishlistStore.toggle(id: id)
        allItems = allItems.map { item in
            guard item.id == id else { return item }
            return RadarFeedItemViewData(
                id: item.id,
                artist: item.artist,
                title: item.title,
                coverAssetName: item.coverAssetName,
                coverImageURL: item.coverImageURL,
                sourceItemURL: item.sourceItemURL,
                storeID: item.storeID,
                sourceName: item.sourceName,
                publishedAtText: item.publishedAtText,
                publishedAt: item.publishedAt,
                badges: item.badges,
                isSaved: wishlistStore.isSaved(id: id)
            )
        }

        applyCurrentFilters()
    }

    private func performLoad(
        countNewItems: Bool,
        showLoadingState: Bool,
        preserveStateOnFailure: Bool
    ) async -> RadarRefreshResult {
        let previousState = state

        if showLoadingState {
            state = .loading
        }

        do {
            if loadDelayNanoseconds > 0 {
                try await Task.sleep(nanoseconds: loadDelayNanoseconds)
            }

            let releases = try await repository.fetchLatest()
            let currentIDs = Set(releases.map(\.id))
            let newCount = countNewItems ? currentIDs.subtracting(seenReleaseIDs).count : 0

            allReleases = releases
            seenReleaseIDs = currentIDs
            lastUpdatedAt = now()

            rebuildAllItems()
            applyCurrentFilters()

            return RadarRefreshResult(didSucceed: true, newFeedCount: newCount)
        } catch is CancellationError {
            if preserveStateOnFailure {
                state = previousState
            } else {
                state = .error("无法刷新 Radar")
            }
            return .failure
        } catch {
            if preserveStateOnFailure {
                state = previousState
            } else {
                state = .error("无法刷新 Radar")
            }
            return .failure
        }
    }

    private func rebuildAllItems() {
        let referenceDate = now()
        allItems = mapper.map(
            releases: allReleases,
            stores: stores,
            wishlistStore: wishlistStore,
            referenceDate: referenceDate
        )

        let availableStoreIDs = Set(allItems.map(\.storeID))
        let intersectedIDs = selectedStoreIDs.intersection(availableStoreIDs)
        if intersectedIDs != selectedStoreIDs {
            selectedStoreIDs = intersectedIDs
        }

        refreshStoreFilterOptions()

        if let lastUpdatedAt {
            summaryData = mapper.summary(
                releases: allReleases,
                stores: stores,
                updatedAt: lastUpdatedAt,
                referenceDate: referenceDate
            )
        }
    }

    private func refreshStoreFilterOptions() {
        storeFilterOptions = mapper.storeFilterOptions(
            from: allItems,
            stores: stores,
            selectedStoreIDs: selectedStoreIDs
        )
    }

    private func applyCurrentFilters() {
        guard lastUpdatedAt != nil else { return }

        let filtered = mapper.apply(
            quickFilter: selectedQuickFilter,
            selectedStoreIDs: selectedStoreIDs,
            to: allItems
        )

        if filtered.isEmpty {
            state = .empty
        } else {
            state = .loaded(filtered)
        }
    }
}

extension RadarFeedViewModel {
    public static func preview(mode: MockRadarFeedRepositoryMode = .resources) -> RadarFeedViewModel {
        RadarFeedViewModel(
            repository: MockRadarFeedRepository(mode: mode),
            stores: MockBootstrap.defaultStores(),
            wishlistStore: InMemoryWishlistStore(ids: ["r2"]),
            layoutStore: InMemoryFeedLayoutStore(layout: .large),
            loadDelayNanoseconds: 0
        )
    }
}
