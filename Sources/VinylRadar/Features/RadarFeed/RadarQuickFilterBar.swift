import SwiftUI

struct RadarQuickFilterBar: View {
    @Binding var selectedFilter: RadarQuickFilter
    let onStoreFilterTap: () -> Void

    var body: some View {
        HStack(spacing: RadarSpacing.xs) {
            RadarQuickFilterChipsView(selectedFilter: $selectedFilter)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipped()

            Button(action: onStoreFilterTap) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(RadarColor.textPrimary)
                    .frame(width: 38, height: 38)
                    .background(RadarColor.surfaceChip.opacity(0.9), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("store_filter_button")
            .accessibilityLabel("筛选店铺")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    RadarQuickFilterBar(selectedFilter: .constant(.all), onStoreFilterTap: {})
        .padding()
        .background(RadarColor.backgroundPrimary)
        .preferredColorScheme(.dark)
}
