import SwiftUI

public struct VinylRadarRootView: View {
    @StateObject private var viewModel: RadarFeedViewModel

    public init(
        repository: (any RadarFeedRepository)? = nil,
        stores: [StoreSource] = MockBootstrap.defaultStores(),
        wishlistStore: WishlistStore = UserDefaultsWishlistStore(),
        layoutStore: FeedLayoutStore = UserDefaultsFeedLayoutStore()
    ) {
        let resolvedRepository = repository ?? Self.makeDefaultRepository()

        _viewModel = StateObject(
            wrappedValue: RadarFeedViewModel(
                repository: resolvedRepository,
                stores: stores,
                wishlistStore: wishlistStore,
                layoutStore: layoutStore
            )
        )
    }

    public var body: some View {
        RadarFeedView(viewModel: viewModel)
    }

    nonisolated static func makeDefaultRepository(
        apiBaseURL: URL? = RadarRuntimeConfig.apiBaseURL,
        cacheStore: any RadarFeedCacheStore = UserDefaultsRadarFeedCacheStore()
    ) -> any RadarFeedRepository {
        let emptyRepository = EmptyRadarFeedRepository()
        let cachedRepository = FallbackRadarFeedRepository(
            primary: CachedRadarFeedRepository(cacheStore: cacheStore),
            fallback: emptyRepository
        )

        guard let apiBaseURL,
              let remoteRepository = try? RemoteRadarFeedRepository(
                baseURL: apiBaseURL,
                cacheStore: cacheStore
              ) else {
            return cachedRepository
        }

        return CachedFirstRadarFeedRepository(
            remote: FallbackRadarFeedRepository(
                primary: remoteRepository,
                fallback: cachedRepository
            ),
            cacheStore: cacheStore
        )
    }
}

#Preview("Dark") {
    VinylRadarRootView(
        repository: MockRadarFeedRepository(),
        stores: MockBootstrap.defaultStores(),
        wishlistStore: InMemoryWishlistStore(),
        layoutStore: InMemoryFeedLayoutStore(layout: .large)
    )
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    VinylRadarRootView(
        repository: MockRadarFeedRepository(),
        stores: MockBootstrap.defaultStores(),
        wishlistStore: InMemoryWishlistStore(),
        layoutStore: InMemoryFeedLayoutStore(layout: .compact)
    )
    .preferredColorScheme(.light)
}
