import SwiftUI

public struct RadarFeedView: View {
    @ObservedObject var viewModel: RadarFeedViewModel

    @State private var selectedItem: RadarFeedItemViewData?
    @State private var activeSheet: FeedPlaceholderSheet?
    @State private var toastMessage: String?
    @State private var summaryAutoHideTask: Task<Void, Never>?

    public init(viewModel: RadarFeedViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: RadarSpacing.lg) {
                    scrollOffsetReader

                    RadarHeaderView(
                        cardLayout: viewModel.cardLayout,
                        onSearchTap: { activeSheet = .search },
                        onToggleLayoutTap: {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                viewModel.toggleCardLayout()
                            }
                        }
                    )

                    if let toastMessage {
                        RadarSummaryStrip(text: toastMessage)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    RadarQuickFilterBar(
                        selectedFilter: $viewModel.selectedQuickFilter,
                        onStoreFilterTap: viewModel.presentStoreFilterSheet
                    )

                    content
                }
                .padding(.horizontal, RadarSpacing.md)
                .padding(.top, RadarSpacing.md)
                .padding(.bottom, 40)
            }
            .coordinateSpace(name: "feedScroll")
            .onPreferenceChange(FeedScrollOffsetPreferenceKey.self, perform: handleScrollOffsetChange)
            .refreshable {
                let result = await viewModel.retry()
                guard result.shouldShowToast else {
                    return
                }
                showSummaryTemporarily(newFeedCount: result.newFeedCount)
            }
            .background(RadarColor.backgroundPrimary.ignoresSafeArea())
            .task {
                await viewModel.loadIfNeeded()
            }
            .onDisappear {
                summaryAutoHideTask?.cancel()
                summaryAutoHideTask = nil
            }
            .sheet(item: $activeSheet) { sheet in
                PlaceholderSheetView(sheet: sheet)
                    .presentationDetents([.fraction(0.25)])
            }
            .sheet(isPresented: $viewModel.isStoreFilterSheetPresented) {
                RadarStoreFilterSheet(
                    options: viewModel.storeFilterOptions,
                    selectedStoreIDs: viewModel.selectedStoreIDs,
                    onApply: viewModel.applyStoreSelection,
                    onDismiss: viewModel.dismissStoreFilterSheet
                )
                .presentationDetents([.fraction(0.45), .large])
            }
            .navigationDestination(item: $selectedItem) { item in
                ReleaseDetailView(item: item)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            LazyVStack(spacing: viewModel.cardLayout == .large ? RadarSpacing.lg : RadarSpacing.sm) {
                ForEach(0..<3, id: \.self) { _ in
                    if viewModel.cardLayout == .large {
                        RadarLoadingCard()
                    } else {
                        RadarLoadingCompactCard()
                    }
                }
            }
        case .loaded(let items):
            RadarFeedListView(
                layout: viewModel.cardLayout,
                items: items,
                onToggleSaved: viewModel.toggleSaved,
                onSelect: { selectedItem = $0 }
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        case .empty:
            RadarEmptyStateView(
                title: "暂无雷达命中",
                subtitle: "尝试切换筛选条件或清空店铺筛选"
            )
        case .error(let message):
            RadarErrorStateView(message: message) {
                Task {
                    _ = await viewModel.retry()
                }
            }
        }
    }

    private var scrollOffsetReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: FeedScrollOffsetPreferenceKey.self,
                    value: proxy.frame(in: .named("feedScroll")).minY
                )
        }
        .frame(height: 0)
    }

    private func handleScrollOffsetChange(_ offset: CGFloat) {
        guard offset < -20 else {
            return
        }

        guard toastMessage != nil else {
            return
        }

        hideToast()
    }

    private func hideToast() {
        summaryAutoHideTask?.cancel()
        summaryAutoHideTask = nil

        withAnimation(.easeInOut(duration: 0.2)) {
            toastMessage = nil
        }
    }

    private func showSummaryTemporarily(newFeedCount: Int) {
        summaryAutoHideTask?.cancel()

        let message = "\(newFeedCount) 个新发售 · \(viewModel.summaryData.followedStoreCount) 个关注店铺 · 刚刚更新"
        withAnimation(.easeInOut(duration: 0.2)) {
            toastMessage = message
        }

        summaryAutoHideTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    toastMessage = nil
                }
                summaryAutoHideTask = nil
            }
        }
    }
}

private struct FeedScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private enum FeedPlaceholderSheet: String, Identifiable {
    case search

    var id: String { rawValue }

    var title: String {
        switch self {
        case .search:
            return "搜索功能二期开放"
        }
    }

    var subtitle: String {
        switch self {
        case .search:
            return "一期先聚焦高质量 Feed 扫描体验"
        }
    }
}

private struct PlaceholderSheetView: View {
    let sheet: FeedPlaceholderSheet

    var body: some View {
        VStack(spacing: RadarSpacing.md) {
            Text(sheet.title)
                .font(.headline)
                .foregroundStyle(RadarColor.textPrimary)

            Text(sheet.subtitle)
                .font(.subheadline)
                .foregroundStyle(RadarColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, RadarSpacing.lg)
        .background(RadarColor.backgroundSecondary)
    }
}

#Preview("Loaded") {
    RadarFeedView(viewModel: .preview())
        .preferredColorScheme(.dark)
}

#Preview("Error") {
    RadarFeedView(viewModel: .preview(mode: .failure))
        .preferredColorScheme(.dark)
}

#Preview("Empty") {
    RadarFeedView(viewModel: .preview(mode: .empty))
        .preferredColorScheme(.dark)
}
