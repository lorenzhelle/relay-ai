import SwiftUI

// Custom font helpers. Falls back gracefully if .ttf files are not yet bundled.
// To enable custom fonts: place font files in relay/Resources/Fonts/ and add
// UIAppFonts entries to relay/Info.plist (see README).

extension Font {
    // Newsreader — serif display/body. Falls back to New York.
    static func newsreader(size: CGFloat, italic: Bool = false) -> Font {
        let name = italic ? "Newsreader-Italic" : "Newsreader-Regular"
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return italic
            ? .system(size: size, design: .serif).italic()
            : .system(size: size, design: .serif)
    }

    // JetBrains Mono — monospaced metadata/CLI. Falls back to SF Mono.
    static func jetbrainsMono(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name = weight == .medium ? "JetBrainsMono-Medium" : "JetBrainsMono-Regular"
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size, design: .monospaced).weight(weight)
    }

    // SF Pro (sans) — UI labels, buttons
    static func relaySans(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}
