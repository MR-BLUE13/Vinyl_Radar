import SwiftUI

struct RadarHeaderView: View {
    let cardLayout: FeedCardLayout
    let onSearchTap: () -> Void
    let onToggleLayoutTap: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: RadarSpacing.xs) {
                Text("Radar")
                    .font(RadarTypography.title)
                    .foregroundStyle(RadarColor.textPrimary)
                Text("Limited Vinyl Drops")
                    .font(RadarTypography.subtitle)
                    .foregroundStyle(RadarColor.textSecondary)
            }

            Spacer(minLength: RadarSpacing.md)

            HStack(spacing: RadarSpacing.xs) {
                headerButton(systemName: "magnifyingglass", action: onSearchTap)
                layoutToggleButton
            }
        }
    }

    private var layoutToggleButton: some View {
        Button(action: onToggleLayoutTap) {
            Image(systemName: cardLayout.toggleIconName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(RadarColor.textPrimary)
                .frame(width: 38, height: 38)
                .background(RadarColor.surfaceChip.opacity(0.85), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("layout_toggle")
        .accessibilityLabel(cardLayout.toggleAccessibilityLabel)
    }

    @ViewBuilder
    private func headerButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(RadarColor.textPrimary)
                .frame(width: 38, height: 38)
                .background(RadarColor.surfaceChip.opacity(0.85), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(systemName)
    }
}

#Preview {
    RadarHeaderView(cardLayout: .large, onSearchTap: {}, onToggleLayoutTap: {})
        .padding()
        .background(RadarColor.backgroundPrimary)
        .preferredColorScheme(.dark)
}
