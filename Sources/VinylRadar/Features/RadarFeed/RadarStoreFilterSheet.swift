import SwiftUI

struct RadarStoreFilterSheet: View {
    let options: [StoreFilterOption]
    let selectedStoreIDs: Set<String>
    let selectedStockFilter: StockAvailabilityFilter
    let onApply: (Set<String>, StockAvailabilityFilter) -> Void
    let onDismiss: () -> Void

    @State private var draftSelectedStoreIDs: Set<String>
    @State private var draftSelectedStockFilter: StockAvailabilityFilter

    init(
        options: [StoreFilterOption],
        selectedStoreIDs: Set<String>,
        selectedStockFilter: StockAvailabilityFilter,
        onApply: @escaping (Set<String>, StockAvailabilityFilter) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.options = options
        self.selectedStoreIDs = selectedStoreIDs
        self.selectedStockFilter = selectedStockFilter
        self.onApply = onApply
        self.onDismiss = onDismiss
        _draftSelectedStoreIDs = State(initialValue: Self.initialSelection(
            from: selectedStoreIDs,
            options: options
        ))
        _draftSelectedStockFilter = State(initialValue: selectedStockFilter)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: RadarSpacing.md) {
                VStack(alignment: .leading, spacing: RadarSpacing.xs) {
                    Text("库存状态")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RadarColor.textSecondary)

                    HStack(spacing: RadarSpacing.xs) {
                        ForEach(StockAvailabilityFilter.allCases) { filter in
                            stockFilterPill(filter: filter)
                        }
                    }
                }

                if options.isEmpty {
                    Text("暂无可筛选店铺")
                        .font(.subheadline)
                        .foregroundStyle(RadarColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, RadarSpacing.xl)
                } else {
                    ScrollView {
                        VStack(spacing: RadarSpacing.xs) {
                            ForEach(options) { option in
                                storeOptionRow(option: option)
                            }
                        }
                    }
                }

                HStack(spacing: RadarSpacing.sm) {
                    Button("清空") {
                        draftSelectedStoreIDs = Set(options.map(\.id))
                        draftSelectedStockFilter = .all
                    }
                    .buttonStyle(.plain)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RadarColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RadarSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: RadarRadius.chip, style: .continuous)
                            .fill(RadarColor.surfaceChip.opacity(0.8))
                    )

                    Button("应用") {
                        onApply(normalizedSelectionForApply(), draftSelectedStockFilter)
                    }
                    .buttonStyle(.plain)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RadarColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RadarSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: RadarRadius.chip, style: .continuous)
                            .fill(RadarColor.surfaceCard)
                    )
                }
            }
            .padding(RadarSpacing.md)
            .background(RadarColor.backgroundSecondary)
            .onAppear {
                draftSelectedStoreIDs = Self.initialSelection(from: selectedStoreIDs, options: options)
                draftSelectedStockFilter = selectedStockFilter
            }
            .navigationTitle("筛选店铺")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") {
                        onDismiss()
                    }
                    .foregroundStyle(RadarColor.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private func storeOptionRow(option: StoreFilterOption) -> some View {
        let isSelected = draftSelectedStoreIDs.contains(option.id)

        Button {
            if isSelected {
                draftSelectedStoreIDs.remove(option.id)
            } else {
                draftSelectedStoreIDs.insert(option.id)
            }
        } label: {
            HStack(spacing: RadarSpacing.sm) {
                Text(option.name)
                    .font(.subheadline)
                    .foregroundStyle(RadarColor.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text("\(option.displayCount(for: draftSelectedStockFilter))")
                    .font(RadarTypography.meta.weight(.medium))
                    .foregroundStyle(RadarColor.textSecondary)
                    .accessibilityIdentifier("store_count_\(option.id)")

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2.weight(.semibold))
                    .frame(width: 32, height: 32)
                    .foregroundStyle(isSelected ? RadarColor.accentExclusive : RadarColor.textSecondary.opacity(0.6))
            }
            .padding(RadarSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: RadarRadius.chip, style: .continuous)
                    .fill(RadarColor.surfaceCard.opacity(0.75))
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("store_filter_\(option.id)")
    }

    @ViewBuilder
    private func stockFilterPill(filter: StockAvailabilityFilter) -> some View {
        let isSelected = draftSelectedStockFilter == filter

        Button {
            draftSelectedStockFilter = filter
        } label: {
            Text(filter.displayTitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(isSelected ? RadarColor.textPrimary : RadarColor.textSecondary)
                .padding(.horizontal, RadarSpacing.md)
                .padding(.vertical, RadarSpacing.sm + 1)
                .background(
                    RoundedRectangle(cornerRadius: RadarRadius.chip, style: .continuous)
                        .fill(isSelected ? RadarColor.surfaceCard : RadarColor.surfaceChip.opacity(0.82))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: RadarRadius.chip, style: .continuous)
                        .stroke(
                            isSelected ? RadarColor.textSecondary.opacity(0.22) : Color.clear,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("stock_filter_\(filter.rawValue)")
    }

    private func normalizedSelectionForApply() -> Set<String> {
        let allStoreIDs = Set(options.map(\.id))
        if draftSelectedStoreIDs.isEmpty || draftSelectedStoreIDs == allStoreIDs {
            return []
        }
        return draftSelectedStoreIDs
    }

    private static func initialSelection(
        from selectedStoreIDs: Set<String>,
        options: [StoreFilterOption]
    ) -> Set<String> {
        let allStoreIDs = Set(options.map(\.id))
        guard !allStoreIDs.isEmpty else { return [] }
        guard !selectedStoreIDs.isEmpty else { return allStoreIDs }

        let intersected = selectedStoreIDs.intersection(allStoreIDs)
        return intersected.isEmpty ? allStoreIDs : intersected
    }
}

#Preview {
    RadarStoreFilterSheet(
        options: [
            StoreFilterOption(id: "store_1", name: "Rare Wax House", totalCount: 4, inStockCount: 2, isSelected: true),
            StoreFilterOption(id: "store_2", name: "Mono Corner", totalCount: 2, inStockCount: 1, isSelected: false),
        ],
        selectedStoreIDs: ["store_1"],
        selectedStockFilter: .all,
        onApply: { _, _ in },
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
