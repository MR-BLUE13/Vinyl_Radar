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

    private static func makeDefaultRepository() -> any RadarFeedRepository {
        guard let apiBaseURL = RadarRuntimeConfig.apiBaseURL else {
            return MockRadarFeedRepository()
        }

        guard let remoteRepository = try? RemoteRadarFeedRepository(baseURL: apiBaseURL) else {
            return MockRadarFeedRepository()
        }

        return FallbackRadarFeedRepository(
            primary: remoteRepository,
            fallback: MockRadarFeedRepository()
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
