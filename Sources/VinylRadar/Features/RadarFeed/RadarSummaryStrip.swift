import SwiftUI

struct RadarSummaryStrip: View {
    private let text: String

    init(summary: RadarSummaryData) {
        self.text = summary.displayText
    }

    init(text: String) {
        self.text = text
    }

    var body: some View {
        HStack(spacing: RadarSpacing.xs) {
            Image(systemName: "bell")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RadarColor.textPrimary.opacity(0.85))
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RadarColor.textPrimary.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, RadarSpacing.sm)
        .padding(.vertical, RadarSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: RadarRadius.chip, style: .continuous)
                .fill(RadarColor.surfaceCard.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: RadarRadius.chip, style: .continuous)
                .stroke(RadarColor.textSecondary.opacity(0.18), lineWidth: 1)
        )
    }
}

#Preview {
    RadarSummaryStrip(summary: .init(newDropsCount: 3, followedStoreCount: 2, updatedText: "刚刚"))
        .padding()
        .background(RadarColor.backgroundPrimary)
        .preferredColorScheme(.dark)
}
