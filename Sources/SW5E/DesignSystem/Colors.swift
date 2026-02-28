import SwiftUI

/// Star Wars-themed color palette for the SW5E iOS app.
/// Dark space aesthetic with hologram-blue accents and tech-orange highlights.
/// NOTE: Using explicit RGB values — Color("#RRGGBB") hex-string initializer
/// is unreliable on iOS 26 beta and will return .clear silently.
extension Color {
    // MARK: - Space Background Colors

    /// Near-black primary background — matte, deep space  (#0A0E1A)
    static let spacePrimary = Color(red: 0.039, green: 0.055, blue: 0.102)

    /// Card/background surface color  (#111827)
    static let spaceCard = Color(red: 0.067, green: 0.094, blue: 0.153)

    // MARK: - Hologram Accents

    /// Primary hologram blue — vibrant, glowing  (#00D4FF)
    static let hologramBlue = Color(red: 0.0, green: 0.831, blue: 1.0)

    /// Subtle hologram blue for borders and muted elements  (#1A3A4A)
    static let holoBlueSubtle = Color(red: 0.102, green: 0.227, blue: 0.290)

    // MARK: - Tech & Faction Colors

    /// Tech orange — UI highlights, action buttons  (#E8700A)
    static let techOrange = Color(red: 0.910, green: 0.439, blue: 0.039)

    /// Sith red — danger, critical states, enemy indicators  (#CC2222)
    static let siithRed = Color(red: 0.800, green: 0.133, blue: 0.133)

    /// Saber green — lightsaber color, positive force effects  (#4ADE80)
    static let saberGreen = Color(red: 0.290, green: 0.871, blue: 0.502)

    // MARK: - Text Colors

    /// Primary light text for readability on dark backgrounds  (#E2E8F0)
    static let lightText = Color(red: 0.886, green: 0.910, blue: 0.941)

    /// Muted secondary text for captions and labels  (#6B7280)
    static let mutedText = Color(red: 0.420, green: 0.447, blue: 0.502)

    // MARK: - Borders & Dividers

    /// Subtle border color for cards and sections  (#1F2937)
    static let borderSubtle = Color(red: 0.122, green: 0.161, blue: 0.216)
}

// MARK: - Preview Provider
#Preview("Color Palette") {
    VStack(spacing: 16) {
        Group {
            colorRow("spacePrimary",  .spacePrimary)
            colorRow("spaceCard",     .spaceCard)
            colorRow("hologramBlue",  .hologramBlue)
            colorRow("techOrange",    .techOrange)
            colorRow("siithRed",      .siithRed)
            colorRow("saberGreen",    .saberGreen)
            colorRow("lightText",     .lightText)
            colorRow("mutedText",     .mutedText)
            colorRow("borderSubtle",  .borderSubtle)
        }
    }
    .background(Color.spaceCard)
    .padding()
}

private func colorRow(_ name: String, _ color: Color) -> some View {
    HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 6)
            .fill(color)
            .frame(width: 36, height: 36)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.2), lineWidth: 1))
        Text(name)
            .font(.caption.monospaced())
            .foregroundStyle(Color.lightText)
        Spacer()
    }
}
