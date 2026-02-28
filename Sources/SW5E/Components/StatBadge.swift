import SwiftUI

/// Compact pill component for displaying ability scores and stats.
struct StatBadge: View {
    let label: String
    let value: Int
    var showModifier: Bool = true

    var formattedValue: String {
        if showModifier && value != 0 {
            return value > 0 ? "+\(value)" : "\(value)"
        }
        return "\(value)"
    }

    var color: Color {
        switch label.uppercased() {
        case "STR": return .saberGreen
        case "DEX": return .hologramBlue
        case "CON": return .techOrange
        case "INT": return .siithRed
        case "WIS": return .hologramBlue
        case "CHA": return .techOrange
        default:    return .lightText
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.labelSmall)
                .foregroundStyle(Color.mutedText)
                .minimumScaleFactor(0.8)

            Spacer()

            Text(formattedValue)
                .font(.dataReadout)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.spaceCard.opacity(0.7))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview("Stat Badge") {
    VStack(spacing: 12) {
        StatBadge(label: "Strength",     value: 16, showModifier: true)
        StatBadge(label: "Dexterity",    value: 14, showModifier: true)
        StatBadge(label: "Constitution", value: 8,  showModifier: true)
        StatBadge(label: "Intelligence", value: 0,  showModifier: false)
    }
    .padding()
}
