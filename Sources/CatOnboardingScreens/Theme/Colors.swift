import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >>  8) & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255,
            opacity: alpha
        )
    }

    // MARK: - Brand Colors
    static let brandPurple    = Color(hex: 0x6B47FF)
    static let brandBlue      = Color(hex: 0x2473FF)
    static let brandCyan      = Color(hex: 0x61D1FF)
    static let brandPink      = Color(hex: 0xFF5FA0)
    static let brandBg        = Color(hex: 0x0A0A0F)
    static let brandSurface   = Color(hex: 0x141419)
    static let brandBorder    = Color(hex: 0x1F1F2A)

    // MARK: - Trait Colors (6 personalities)
    static let traitLove          = Color(hex: 0xFF8FAD) // 💕
    static let traitManipulation  = Color(hex: 0x7C3AED) // 🎭 (darker to avoid brand clash)
    static let traitColdness      = Color(hex: 0x61D1FF) // 🧊
    static let traitSass          = Color(hex: 0xFF4D8F) // 💅 (magenta, not pink)
    static let traitCuriosity     = Color(hex: 0x66D98C) // 🔍
    static let traitChaos         = Color(hex: 0xFF8C33) // 😈

    // MARK: - Streak States
    static let streakHot    = Color(hex: 0xFF6B00)
    static let streakRed    = Color(hex: 0xFF0033)
    static let streakRisk   = Color(hex: 0xFFB800)
    static let streakSafe   = Color(hex: 0x66D98C)
    static let streakLost   = Color(hex: 0xFF4D6D)
    static let streakGray   = Color(hex: 0x808080)

    // MARK: - Text Colors
    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.78)
    static let textTertiary  = Color.white.opacity(0.56)
    static let textDisabled  = Color.white.opacity(0.42)
    static let textSubtle    = Color.white.opacity(0.38)

    // MARK: - Border Colors
    static let borderDefault = Color.white.opacity(0.08)
    static let borderHover   = Color.white.opacity(0.12)
    static let borderActive  = Color.white.opacity(0.20)
}

// MARK: - Gradients

extension LinearGradient {
    /// Primary brand gradient (purple to blue)
    static let brand = LinearGradient(
        colors: [.brandPurple, .brandBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Secondary brand gradient (cyan to purple)
    static let brandSecondary = LinearGradient(
        colors: [.brandCyan, .brandPurple],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Active streak gradient (orange to red)
    static let streakActive = LinearGradient(
        colors: [.streakHot, .streakRed],
        startPoint: .top,
        endPoint: .bottom
    )

    /// At-risk streak gradient
    static let streakAtRisk = LinearGradient(
        colors: [.streakRisk, .streakHot],
        startPoint: .top,
        endPoint: .bottom
    )

    /// No streak gradient
    static let streakInactive = LinearGradient(
        colors: [.streakGray, .streakGray.opacity(0.7)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Trait Color Helper
//
// In production this extension wraps a `ScanTraitType` enum from the main
// scanner module. The onboarding never calls it directly (each
// `OnboardingTrait` exposes its own `.color`), so the helper is omitted
// from the standalone package to avoid pulling in that whole module.

// MARK: - ShapeStyle leading-dot shorthand
//
// Lets us write `.foregroundStyle(.brandPurple)`, `.fill(.traitLove)`,
// `.foregroundStyle(.textPrimary)` etc. — the same ergonomics SwiftUI gives
// us for `.red`, `.blue`. Without this, the leading-dot only resolves names
// declared on `ShapeStyle` itself, not on `Color`, and you get
// `type 'ShapeStyle' has no member 'brandPurple'`.
//
// Mirrors every Color token defined above. No new color values are introduced.
extension ShapeStyle where Self == Color {
    // Brand
    static var brandPurple:   Color { Color.brandPurple }
    static var brandBlue:     Color { Color.brandBlue }
    static var brandCyan:     Color { Color.brandCyan }
    static var brandPink:     Color { Color.brandPink }
    static var brandBg:       Color { Color.brandBg }
    static var brandSurface:  Color { Color.brandSurface }
    static var brandBorder:   Color { Color.brandBorder }

    // Traits
    static var traitLove:         Color { Color.traitLove }
    static var traitManipulation: Color { Color.traitManipulation }
    static var traitColdness:     Color { Color.traitColdness }
    static var traitSass:         Color { Color.traitSass }
    static var traitCuriosity:    Color { Color.traitCuriosity }
    static var traitChaos:        Color { Color.traitChaos }

    // Streak
    static var streakHot:   Color { Color.streakHot }
    static var streakRed:   Color { Color.streakRed }
    static var streakRisk:  Color { Color.streakRisk }
    static var streakSafe:  Color { Color.streakSafe }
    static var streakLost:  Color { Color.streakLost }
    static var streakGray:  Color { Color.streakGray }

    // Text levels (white at opacity)
    static var textPrimary:   Color { Color.textPrimary }
    static var textSecondary: Color { Color.textSecondary }
    static var textTertiary:  Color { Color.textTertiary }
    static var textDisabled:  Color { Color.textDisabled }
    static var textSubtle:    Color { Color.textSubtle }

    // Borders
    static var borderDefault: Color { Color.borderDefault }
    static var borderHover:   Color { Color.borderHover }
    static var borderActive:  Color { Color.borderActive }
}
