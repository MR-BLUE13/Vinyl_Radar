import SwiftUI

struct RadarErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: RadarSpacing.md) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(RadarColor.textSecondary)

            VStack(spacing: RadarSpacing.xs) {
                Text("无法刷新 Radar")
                    .font(.headline)
                    .foregroundStyle(RadarColor.textPrimary)
                Text(message)
                    .font(RadarTypography.meta)
                    .foregroundStyle(RadarColor.textSecondary)
            }

            Button(action: onRetry) {
                Text("点击重试")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RadarColor.textPrimary)
                    .padding(.horizontal, RadarSpacing.md)
                    .padding(.vertical, RadarSpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: RadarRadius.chip, style: .continuous)
                            .fill(RadarColor.surfaceChip)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("retry_button")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .background(
            RoundedRectangle(cornerRadius: RadarRadius.card, style: .continuous)
                .fill(RadarColor.surfaceCard.opacity(0.75))
        )
    }
}

#Preview {
    RadarErrorStateView(message: "请检查网络后再试", onRetry: {})
        .padding()
        .background(RadarColor.backgroundPrimary)
        .preferredColorScheme(.dark)
}
