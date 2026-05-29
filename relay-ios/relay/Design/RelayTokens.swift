import SwiftUI

// MARK: - Color tokens

extension Color {
    static let relayBg      = Color(relayHex: "#F2EEE4")
    static let relayPaper   = Color(relayHex: "#FAF6EC")
    static let relayInk     = Color(relayHex: "#181613")
    static let relayMuted   = Color(relayHex: "#181613").opacity(0.58)
    static let relayFaint   = Color(relayHex: "#181613").opacity(0.34)
    static let relayHair    = Color(relayHex: "#181613").opacity(0.09)
    static let relayHair2   = Color(relayHex: "#181613").opacity(0.16)
    static let relaySage    = Color(relayHex: "#6D8C7A")   // oklch(0.58 0.055 165)
    static let relayAmber   = Color(relayHex: "#C8823A")   // oklch(0.66 0.14 55)
    static let relayRust    = Color(relayHex: "#B45A3C")   // oklch(0.55 0.14 28)
    static let relayOnInk   = Color(relayHex: "#F8F4EA")   // text on dark surfaces

    init(relayHex hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (1, 1, 1)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

// MARK: - Spacing tokens

enum RelaySpacing {
    static let screenH: CGFloat     = 26   // horizontal screen padding
    static let screenHWide: CGFloat = 28   // wider variant used in body sections
    static let headerTop: CGFloat   = 60
    static let headerBottom: CGFloat = 18
    static let ctaBottom: CGFloat   = 34
    static let cardPad: CGFloat     = 16
    static let cardRadius: CGFloat  = 14
    static let buttonHeight: CGFloat = 60
    static let buttonRadius: CGFloat = 18
    static let hairline: CGFloat    = 0.5
}
