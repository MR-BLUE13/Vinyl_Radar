import SwiftUI

struct RadarQuickFilterChipsView: View {
    @Binding var selectedFilter: RadarQuickFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RadarSpacing.xs) {
                ForEach(RadarQuickFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.displayTitle)
                            .font(RadarTypography.meta.weight(.medium))
                            .foregroundStyle(selectedFilter == filter ? RadarColor.textPrimary : RadarColor.textSecondary)
                            .padding(.horizontal, RadarSpacing.sm)
                            .padding(.vertical, RadarSpacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: RadarRadius.chip, style: .continuous)
                                    .fill(selectedFilter == filter ? RadarColor.surfaceCard : RadarColor.surfaceChip.opacity(0.82))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: RadarRadius.chip, style: .continuous)
                                    .stroke(
                                        selectedFilter == filter ? RadarColor.textSecondary.opacity(0.22) : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("chip_\(filter.rawValue)")
                }
            }
            .padding(.vertical, 2)
        }
    }
}

#Preview {
    RadarQuickFilterChipsView(selectedFilter: .constant(.all))
        .padding()
        .background(RadarColor.backgroundPrimary)
        .preferredColorScheme(.dark)
}
