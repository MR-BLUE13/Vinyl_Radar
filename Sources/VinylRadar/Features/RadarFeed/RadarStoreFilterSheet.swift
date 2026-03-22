import SwiftUI

struct RadarStoreFilterSheet: View {
    let options: [StoreFilterOption]
    let selectedStoreIDs: Set<String>
    let onApply: (Set<String>) -> Void
    let onDismiss: () -> Void

    @State private var draftSelectedStoreIDs: Set<String>

    init(
        options: [StoreFilterOption],
        selectedStoreIDs: Set<String>,
        onApply: @escaping (Set<String>) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.options = options
        self.selectedStoreIDs = selectedStoreIDs
        self.onApply = onApply
        self.onDismiss = onDismiss
        _draftSelectedStoreIDs = State(initialValue: selectedStoreIDs)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: RadarSpacing.md) {
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
                        draftSelectedStoreIDs.removeAll()
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
                        onApply(draftSelectedStoreIDs)
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

                Text("\(option.count)")
                    .font(RadarTypography.meta.weight(.medium))
                    .foregroundStyle(RadarColor.textSecondary)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
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
}

#Preview {
    RadarStoreFilterSheet(
        options: [
            StoreFilterOption(id: "store_1", name: "Rare Wax House", count: 4, isSelected: true),
            StoreFilterOption(id: "store_2", name: "Mono Corner", count: 2, isSelected: false),
        ],
        selectedStoreIDs: ["store_1"],
        onApply: { _ in },
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
