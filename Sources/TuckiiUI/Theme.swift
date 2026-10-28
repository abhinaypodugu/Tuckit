import SwiftUI

public enum Theme {
    public static let cream = Color(hex: 0xFAF6EC)
    public static let ink = Color(hex: 0x0F0F0F)
    public static let highlighter = Color(hex: 0xFFD147)
    public static let ctaYellow = Color(hex: 0xFFCF5C)
    public static let green = Color(hex: 0x25D0A0)
    public static let danger = Color(hex: 0xF0526B)
    public static let darkBackground = Color(hex: 0x101014)
    public static let darkCard = Color(hex: 0x2B2C33)
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
