import SwiftUI

/// Echoveil color palette — gold sigil, violet Veil energy, deep space navy.
/// NOTE: Using explicit RGB values — Color("#RRGGBB") is unreliable on iOS 26.
extension Color {
    // MARK: - Space Background Colors

    /// Near-black primary background — deep space  (#0A0E1A)
    static let spacePrimary = Color(red: 0.039, green: 0.055, blue: 0.102)

    /// Card/surface color  (#111827)
    static let spaceCard = Color(red: 0.067, green: 0.094, blue: 0.153)

    // MARK: - Veil Gold (Primary Accent)

    /// Primary Veil gold — sigil color, action buttons, highlights  (#D4AF37)
    static let veilGold = Color(red: 0.831, green: 0.686, blue: 0.216)

    /// Subtle gold for borders, muted gold elements  (#2A1F05)
    static let veilGoldSubtle = Color(red: 0.165, green: 0.122, blue: 0.020)

    // MARK: - Veil Energy (Secondary Accent)

    /// Veil purple — energy effects, Tidecaller indicators  (#9333EA)
    static let veilPurple = Color(red: 0.576, green: 0.200, blue: 0.918)

    /// Soft violet glow — Veil aura, passive effects  (#A78BFA)
    static let veilGlow = Color(red: 0.655, green: 0.545, blue: 0.980)

    /// Deep violet surface — Veil-touched cards, active states  (#2D1B69)
    static let veilDeep = Color(red: 0.176, green: 0.106, blue: 0.412)

    // MARK: - Faction & State Colors

    /// Voidshaper red — danger, critical, Void corruption  (#CC2222)
    static let voidRed = Color(red: 0.800, green: 0.133, blue: 0.133)

    /// Sovereignty grey — neutral, Imperial-coded elements  (#4B5563)
    static let sovereigntyGrey = Color(red: 0.294, green: 0.333, blue: 0.388)

    /// Success / Veil harmony green  (#22C55E)
    static let veilHarmony = Color(red: 0.133, green: 0.773, blue: 0.369)

    // MARK: - Text Colors

    /// Primary light text  (#E2E8F0)
    static let lightText = Color(red: 0.886, green: 0.910, blue: 0.941)

    /// Muted secondary text  (#6B7280)
    static let mutedText = Color(red: 0.420, green: 0.447, blue: 0.502)

    // MARK: - Borders & Dividers

    /// Subtle border  (#1F2937)
    static let borderSubtle = Color(red: 0.122, green: 0.161, blue: 0.216)
}
