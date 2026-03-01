import SwiftUI

/// A card component with dark background, holographic blue border, and subtle glow effect.
struct HologramCard: View {
    var title: String? = nil
    let content: String
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.holoDisplay)
                    .foregroundStyle(Color.hologramBlue)
            }
            Text(content)
                .font(.bodyText)
                .foregroundStyle(Color.lightText)
        }
        .padding(16)
        .background(Color.spaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isHovered ? Color.hologramBlue : Color.borderSubtle,
                    lineWidth: isHovered ? 2 : 1
                )
        )
        .shadow(
            color: isHovered ? Color.hologramBlue.opacity(0.3) : Color.black.opacity(0.5),
            radius: isHovered ? 8 : 4, x: 0, y: 4
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
}

// MARK: - Preview
#Preview("Hologram Card") {
    VStack(spacing: 16) {
        HologramCard(title: "Character Stats", content: "Strength +3, Dexterity +2, Constitution +4")
        HologramCard(content: "Level 5 Tidecaller\nCurrent HP: 38/40\nAC: 18\nInitiative: +2")
    }
    .padding()
}
