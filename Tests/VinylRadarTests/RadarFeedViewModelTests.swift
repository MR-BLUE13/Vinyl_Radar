import Foundation
import Testing
@testable import VinylRadar

@Suite("RadarFeedViewModelTests")
@MainActor
struct RadarFeedViewModelTests {
    @Test("toggleCardLayout switches and persists")
    func toggleCardLayout() {
        let layoutStore = InMemoryFeedLayoutStore(layout: .large)
        let viewModel = makeViewModel(layoutStore: layoutStore)

        #expect(viewModel.cardLayout == .large)
        viewModel.toggleCardLayout()
        #expect(viewModel.cardLayout == .compact)
        #expect(layoutStore.current() == .compact)
    }

    @Test("saved filter returns only saved releases")
    func savedFilter() async {
        let viewModel = makeViewModel(savedIDs: ["r2"])
        await viewModel.load()

        viewModel.selectedQuickFilter = .saved

        let loaded = loadedItems(from: viewModel.state)
        #expect(loaded?.count == 1)
        #expect(loaded?.first?.id == "r2")
    }

    @Test("store filter supports multiple store IDs")
    func multiStoreFilter() async {
        let viewModel = makeViewModel(savedIDs: [])
        await viewModel.load()

        viewModel.applyStoreSelection(["s1", "s2"], stockFilter: .all)

        let loaded = loadedItems(from: viewModel.state)
        #expect(loaded?.count == 3)
        #expect(Set(loaded?.map { $0.storeID } ?? []) == ["s1", "s2"])
    }

    @Test("quick filter and store filter use AND logic")
    func quickAndStoreFilter() async {
        let viewModel = makeViewModel(savedIDs: [])
        await viewModel.load()

        viewModel.selectedQuickFilter = .exclusive
        viewModel.applyStoreSelection(["s2"], stockFilter: .all)

        let loaded = loadedItems(from: viewModel.state)
        #expect(loaded?.count == 1)
        #expect(loaded?.first?.id == "r2")
    }

    @Test("empty store selection means all stores")
    func emptyStoreSelectionMeansAll() async {
        let viewModel = makeViewModel(savedIDs: [])
        await viewModel.load()

        viewModel.applyStoreSelection([], stockFilter: .all)

        let loaded = loadedItems(from: viewModel.state)
        #expect(loaded?.count == 4)
    }

    @Test("retry returns new feed count for toast")
    func retryDetectsNewFeeds() async {
        let reference = Date(timeIntervalSince1970: 1_700_000_000)
        let initial = [
            makeRelease(id: "r1", storeID: "s1", minutesAgo: 5, flags: [.isLimited], reference: reference),
            makeRelease(id: "r2", storeID: "s2", minutesAgo: 4, flags: [.isExclusive], reference: reference),
        ]
        let updated = initial + [
            makeRelease(id: "r3", storeID: "s3", minutesAgo: 1, flags: [.isNew], reference: reference),
        ]

        let repo = SequenceRadarFeedRepository(batches: [initial, updated])
        let stores = [
            makeStore(id: "s1", followed: true, name: "Store 1"),
            makeStore(id: "s2", followed: false, name: "Store 2"),
            makeStore(id: "s3", followed: false, name: "Store 3"),
        ]

        let viewModel = RadarFeedViewModel(
            repository: repo,
            stores: stores,
            wishlistStore: InMemoryWishlistStore(),
            layoutStore: InMemoryFeedLayoutStore(layout: .large),
            now: { reference },
            loadDelayNanoseconds: 0
        )

        await viewModel.load()
        let result = await viewModel.retry()

        #expect(result.didSucceed)
        #expect(result.newFeedCount == 1)
        #expect(result.shouldShowToast)
    }

    @Test("retry failure keeps current feed state")
    func retryFailureKeepsExistingState() async {
        let reference = Date(timeIntervalSince1970: 1_700_000_000)
        let initial = [
            makeRelease(id: "r1", storeID: "s1", minutesAgo: 5, flags: [.isLimited], reference: reference),
            makeRelease(id: "r2", storeID: "s2", minutesAgo: 4, flags: [.isExclusive], reference: reference),
        ]

        let repo = SequenceRadarFeedRepository(
            batches: [.success(initial), .failure(MockRadarFeedRepositoryError.forcedFailure)]
        )
        let stores = [
            makeStore(id: "s1", followed: true, name: "Store 1"),
            makeStore(id: "s2", followed: false, name: "Store 2"),
        ]

        let viewModel = RadarFeedViewModel(
            repository: repo,
            stores: stores,
            wishlistStore: InMemoryWishlistStore(),
            layoutStore: InMemoryFeedLayoutStore(layout: .large),
            now: { reference },
            loadDelayNanoseconds: 0
        )

        await viewModel.load()
        #expect(loadedItems(from: viewModel.state)?.count == 2)

        let result = await viewModel.retry()
        #expect(!result.didSucceed)
        #expect(result.newFeedCount == 0)
        #expect(loadedItems(from: viewModel.state)?.count == 2)
    }

    @Test("load uses non-forced refresh")
    func loadUsesNonForcedRefresh() async {
        let reference = Date(timeIntervalSince1970: 1_700_000_000)
        let releases = [
            makeRelease(id: "r1", storeID: "s1", minutesAgo: 3, flags: [.isLimited], reference: reference),
        ]
        let repository = ForceRefreshProbeRepository(releases: releases)

        let viewModel = RadarFeedViewModel(
            repository: repository,
            stores: [makeStore(id: "s1", name: "Store 1")],
            wishlistStore: InMemoryWishlistStore(),
            layoutStore: InMemoryFeedLayoutStore(layout: .large),
            now: { reference },
            loadDelayNanoseconds: 0
        )

        await viewModel.load()
        #expect(await repository.receivedForceRefresh == [false])
    }

    @Test("retry can use forced refresh")
    func retryUsesForcedRefresh() async {
        let reference = Date(timeIntervalSince1970: 1_700_000_000)
        let releases = [
            makeRelease(id: "r1", storeID: "s1", minutesAgo: 3, flags: [.isLimited], reference: reference),
        ]
        let repository = ForceRefreshProbeRepository(releases: releases)

        let viewModel = RadarFeedViewModel(
            repository: repository,
            stores: [makeStore(id: "s1", name: "Store 1")],
            wishlistStore: InMemoryWishlistStore(),
            layoutStore: InMemoryFeedLayoutStore(layout: .large),
            now: { reference },
            loadDelayNanoseconds: 0
        )

        await viewModel.load()
        _ = await viewModel.retry(forceRefresh: true)

        #expect(await repository.receivedForceRefresh == [false, true])
    }

    @Test("quick filter, stock filter, and store filter use AND logic")
    func quickStockAndStoreFilter() async {
        let reference = Date(timeIntervalSince1970: 1_700_000_000)
        let releases = [
            makeRelease(id: "r1", storeID: "s1", minutesAgo: 3, flags: [.isExclusive], isSoldOut: false, reference: reference),
            makeRelease(id: "r2", storeID: "s1", minutesAgo: 4, flags: [.isExclusive], isSoldOut: true, reference: reference),
            makeRelease(id: "r3", storeID: "s2", minutesAgo: 5, flags: [.isExclusive], isSoldOut: false, reference: reference),
        ]

        let viewModel = RadarFeedViewModel(
            repository: MockRadarFeedRepository(mode: .custom(releases)),
            stores: [
                makeStore(id: "s1", name: "Store 1"),
                makeStore(id: "s2", name: "Store 2"),
            ],
            wishlistStore: InMemoryWishlistStore(),
            layoutStore: InMemoryFeedLayoutStore(layout: .large),
            now: { reference },
            loadDelayNanoseconds: 0
        )

        await viewModel.load()
        viewModel.selectedQuickFilter = .exclusive
        viewModel.applyStoreSelection(["s1"], stockFilter: .inStock)

        let loaded = loadedItems(from: viewModel.state)
        #expect(loaded?.map { $0.id } == ["r1"])
    }

    private func makeViewModel(
        savedIDs: Set<String> = [],
        layoutStore: FeedLayoutStore = InMemoryFeedLayoutStore(layout: .large)
    ) -> RadarFeedViewModel {
        let reference = Date(timeIntervalSince1970: 1_700_000_000)
        let releases = [
            makeRelease(id: "r1", storeID: "s1", minutesAgo: 3, flags: [.isLimited], reference: reference),
            makeRelease(id: "r2", storeID: "s2", minutesAgo: 4, flags: [.isExclusive], reference: reference),
            makeRelease(id: "r3", storeID: "s2", minutesAgo: 8, flags: [.isColored], reference: reference),
            makeRelease(id: "r4", storeID: "s3", minutesAgo: 9, flags: [], reference: reference),
        ]

        let stores = [
            makeStore(id: "s1", followed: true, name: "Store 1"),
            makeStore(id: "s2", followed: false, name: "Store 2"),
            makeStore(id: "s3", followed: false, name: "Store 3"),
        ]

        return RadarFeedViewModel(
            repository: MockRadarFeedRepository(mode: .custom(releases)),
            stores: stores,
            wishlistStore: InMemoryWishlistStore(ids: savedIDs),
            layoutStore: layoutStore,
            now: { reference },
            loadDelayNanoseconds: 0
        )
    }

    private func loadedItems(from state: RadarFeedState) -> [RadarFeedItemViewData]? {
        if case .loaded(let items) = state {
            return items
        }
        return nil
    }
}

private actor SequenceRadarFeedRepository: RadarFeedRepository {
    enum Batch {
        case success([ReleaseDrop])
        case failure(Error)
    }

    private let batches: [Batch]
    private var index: Int = 0

    init(batches: [[ReleaseDrop]]) {
        self.batches = batches.map { .success($0) }
    }

    init(batches: [Batch]) {
        self.batches = batches
    }

    func fetchLatest(forceRefresh: Bool) async throws -> [ReleaseDrop] {
        let current = min(index, batches.count - 1)
        let value = batches[current]
        if index < batches.count - 1 {
            index += 1
        }
        switch value {
        case .success(let releases):
            return releases
        case .failure(let error):
            throw error
        }
    }
}

private actor ForceRefreshProbeRepository: RadarFeedRepository {
    private let releases: [ReleaseDrop]
    private(set) var receivedForceRefresh: [Bool] = []

    init(releases: [ReleaseDrop]) {
        self.releases = releases
    }

    func fetchLatest(forceRefresh: Bool) async throws -> [ReleaseDrop] {
        receivedForceRefresh.append(forceRefresh)
        return releases
    }
}
