import SwiftUI

struct RadarLoadingCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: RadarRadius.card, style: .continuous)
            .fill(RadarColor.surfaceCard.opacity(0.8))
            .overlay {
                VStack(alignment: .leading, spacing: RadarSpacing.sm) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(RadarColor.textSecondary.opacity(0.24))
                        .frame(width: 68, height: 24)

                    Spacer()

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(RadarColor.textSecondary.opacity(0.28))
                        .frame(height: 18)
                        .frame(maxWidth: 220)

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(RadarColor.textSecondary.opacity(0.22))
                        .frame(height: 14)
                        .frame(maxWidth: 280)

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(RadarColor.textSecondary.opacity(0.18))
                        .frame(height: 12)
                        .frame(maxWidth: 180)
                }
                .padding(RadarSpacing.md)
            }
            .aspectRatio(0.78, contentMode: .fit)
            .redacted(reason: .placeholder)
            .shimmer()
    }
}

struct RadarLoadingCompactCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: RadarRadius.card, style: .continuous)
            .fill(RadarColor.surfaceCard.opacity(0.8))
            .frame(height: 128)
            .overlay {
                HStack(spacing: RadarSpacing.sm) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(RadarColor.textSecondary.opacity(0.24))
                        .frame(width: 92, height: 92)

                    VStack(alignment: .leading, spacing: RadarSpacing.xs) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(RadarColor.textSecondary.opacity(0.26))
                            .frame(width: 150, height: 16)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(RadarColor.textSecondary.opacity(0.2))
                            .frame(height: 14)
                            .frame(maxWidth: 220)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(RadarColor.textSecondary.opacity(0.18))
                            .frame(width: 140, height: 12)

                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(RadarColor.textSecondary.opacity(0.18))
                                .frame(width: 46, height: 16)

                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(RadarColor.textSecondary.opacity(0.16))
                                .frame(width: 46, height: 16)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(RadarSpacing.sm)
            }
            .redacted(reason: .placeholder)
            .shimmer()
    }
}

#Preview {
    VStack(spacing: RadarSpacing.md) {
        RadarLoadingCard()
        RadarLoadingCompactCard()
    }
    .padding()
    .background(RadarColor.backgroundPrimary)
    .preferredColorScheme(.dark)
}
