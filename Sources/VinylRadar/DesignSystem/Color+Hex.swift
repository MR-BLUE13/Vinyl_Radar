import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        #if canImport(UIKit)
        return Color(
            UIColor { trait in
                if trait.userInterfaceStyle == .dark {
                    return UIColor(red: CGFloat((dark >> 16) & 0xFF) / 255,
                                   green: CGFloat((dark >> 8) & 0xFF) / 255,
                                   blue: CGFloat(dark & 0xFF) / 255,
                                   alpha: 1)
                }
                return UIColor(red: CGFloat((light >> 16) & 0xFF) / 255,
                               green: CGFloat((light >> 8) & 0xFF) / 255,
                               blue: CGFloat(light & 0xFF) / 255,
                               alpha: 1)
            }
        )
        #elseif canImport(AppKit)
        return Color(
            NSColor(name: nil) { appearance in
                let colorHex: UInt32
                if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                    colorHex = dark
                } else {
                    colorHex = light
                }
                return NSColor(
                    red: CGFloat((colorHex >> 16) & 0xFF) / 255,
                    green: CGFloat((colorHex >> 8) & 0xFF) / 255,
                    blue: CGFloat(colorHex & 0xFF) / 255,
                    alpha: 1
                )
            }
        )
        #else
        return Color(hex: dark)
        #endif
    }
}
