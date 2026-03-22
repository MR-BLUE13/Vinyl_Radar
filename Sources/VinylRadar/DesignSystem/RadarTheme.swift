import SwiftUI

public enum RadarColor {
    public static let backgroundPrimary = Color.adaptive(light: 0xF5F3EF, dark: 0x11100F)
    public static let backgroundSecondary = Color.adaptive(light: 0xEBE8E1, dark: 0x171513)
    public static let surfaceCard = Color.adaptive(light: 0xFFFFFF, dark: 0x1B1917)
    public static let surfaceChip = Color.adaptive(light: 0xE4DFD6, dark: 0x25221E)
    public static let textPrimary = Color.adaptive(light: 0x1D1B19, dark: 0xF4F2EE)
    public static let textSecondary = Color.adaptive(light: 0x5B5650, dark: 0xB6B1A8)

    public static let accentNew = Color.adaptive(light: 0x8C2A3A, dark: 0x7A1E2C)
    public static let accentExclusive = Color.adaptive(light: 0x9C7A38, dark: 0x8C6A2E)
    public static let accentLimited = Color.adaptive(light: 0x6A4450, dark: 0x5E3A44)
    public static let accentColored = Color.adaptive(light: 0x59606A, dark: 0x4B5058)

    public static let overlayStrong = Color.black.opacity(0.68)
    public static let overlaySoft = Color.black.opacity(0.3)

    public static func badgeColor(_ badge: RadarBadge) -> Color {
        switch badge {
        case .new:
            return accentNew
        case .exclusive:
            return accentExclusive
        case .limited:
            return accentLimited
        case .colored:
            return accentColored
        }
    }
}

public enum RadarSpacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 20
    public static let xl: CGFloat = 24
}

public enum RadarRadius {
    public static let card: CGFloat = 20
    public static let chip: CGFloat = 14
    public static let badge: CGFloat = 8
}

public enum RadarTypography {
    public static let title = Font.largeTitle.weight(.bold)
    public static let subtitle = Font.subheadline.weight(.regular)
    public static let artist = Font.headline.weight(.semibold)
    public static let release = Font.subheadline.weight(.medium)
    public static let meta = Font.caption
    public static let badge = Font.caption2.weight(.semibold)
}
