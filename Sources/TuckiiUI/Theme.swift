import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public enum Theme {
    public static let background = dynamic(light: 0xFAF6EC, dark: 0x101014)
    public static let cream = background
    public static let ink = dynamic(light: 0x0F0F0F, dark: 0xF2F2EE)
    public static let highlighter = Color(hex: 0xFFD147)
    public static let ctaYellow = Color(hex: 0xFFCF5C)
    public static let green = Color(hex: 0x25D0A0)
    public static let danger = Color(hex: 0xF0526B)
    public static let card = dynamic(light: 0xFFFFFF, dark: 0x24252B)
    public static let field = dynamic(light: 0xFFFFFF, dark: 0x2C2D34)
    public static let fieldWarm = dynamic(light: 0xFDF6E3, dark: 0x3A3320)
    public static let selectedRow = dynamic(light: 0xFDF3D6, dark: 0x3C3620)
    public static let chipGreen = dynamic(light: 0xDFF3E9, dark: 0x1F3A2F)
    public static let statBlue = dynamic(light: 0xD8ECFA, dark: 0x1E3A4C)
    public static let statYellow = dynamic(light: 0xFBE3A6, dark: 0x4A3B12)
    public static let banner = dynamic(light: 0xE9F7EF, dark: 0x16281F)

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hexValue: dark)
                : UIColor(hexValue: light)
        })
        #else
        return Color(hex: light)
        #endif
    }
}

public extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

#if canImport(UIKit)
extension UIColor {
    convenience init(hexValue: UInt32) {
        self.init(
            red: CGFloat((hexValue >> 16) & 0xFF) / 255,
            green: CGFloat((hexValue >> 8) & 0xFF) / 255,
            blue: CGFloat(hexValue & 0xFF) / 255,
            alpha: 1
        )
    }
}
#endif
