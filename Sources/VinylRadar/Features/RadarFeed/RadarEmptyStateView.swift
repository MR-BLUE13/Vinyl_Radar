import SwiftUI

struct RadarEmptyStateView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: RadarSpacing.md) {
            Image(systemName: "recordingtape")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(RadarColor.textSecondary)

            VStack(spacing: RadarSpacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(RadarColor.textPrimary)
                Text(subtitle)
                    .font(RadarTypography.meta)
                    .foregroundStyle(RadarColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, RadarSpacing.lg)
        .padding(.vertical, 42)
        .background(
            RoundedRectangle(cornerRadius: RadarRadius.card, style: .continuous)
                .fill(RadarColor.surfaceCard.opacity(0.7))
        )
    }
}

#Preview {
    RadarEmptyStateView(
        title: "暂无雷达命中",
        subtitle: "关注艺人或店铺后，这里会出现新的限量发售信息"
    )
    .padding()
    .background(RadarColor.backgroundPrimary)
    .preferredColorScheme(.dark)
}
