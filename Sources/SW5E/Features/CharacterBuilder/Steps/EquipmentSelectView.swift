import SwiftUI

// MARK: - Step 6: Starting Equipment

struct EquipmentSelectView: View {
    @ObservedObject var vm: CharacterBuilderViewModel

    // Standard carry weight limit (Strength × 15 in 5E)
    private let carryLimit: Double = 75.0

    private var totalWeight: Double {
        vm.draft.selectedEquipment.filter { $0.isSelected }.reduce(0) { $0 + $1.weight }
    }

    private var encumbranceRatio: Double {
        min(totalWeight / carryLimit, 1.0)
    }

    private var encumbranceColor: Color {
        if encumbranceRatio < 0.5 { return .veilGlow }
        if encumbranceRatio < 0.75 { return .veilPurple }
        return .voidRed
    }

    // Group equipment by type
    private var groupedEquipment: [(type: String, items: [(index: Int, item: CBEquipment)])] {
        let order = ["weapon", "armor", "gear", "consumable"]
        var groups: [String: [(index: Int, item: CBEquipment)]] = [:]
        for (i, item) in vm.draft.selectedEquipment.enumerated() {
            groups[item.type, default: []].append((index: i, item: item))
        }
        return order.compactMap { type in
            guard let items = groups[type], !items.isEmpty else { return nil }
            return (type: type, items: items)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Starting Equipment")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.lightText)
                    Text("Default gear is pre-selected for your class. Toggle items to customize.")
                        .font(.subheadline)
                        .foregroundStyle(Color.mutedText)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Encumbrance meter
                EncumbranceBar(
                    totalWeight: totalWeight,
                    carryLimit: carryLimit,
                    color: encumbranceColor
                )
                .padding(.horizontal, 16)

                // Equipment sections by type
                if vm.draft.selectedEquipment.isEmpty {
                    Text("No equipment available. Select a class first.")
                        .font(.subheadline)
                        .foregroundStyle(Color.mutedText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    ForEach(groupedEquipment, id: \.type) { group in
                        EquipmentSection(
                            type: group.type,
                            items: group.items,
                            onToggle: { index in vm.toggleEquipment(at: index) }
                        )
                        .padding(.horizontal, 16)
                    }
                }

                Spacer(minLength: 20)
            }
        }
        .background(Color.spacePrimary)
    }
}

// MARK: - Encumbrance Bar

private struct EncumbranceBar: View {
    let totalWeight: Double
    let carryLimit: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Encumbrance", systemImage: "backpack.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.mutedText)
                Spacer()
                Text(String(format: "%.1f / %.0f lb", totalWeight, carryLimit))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.borderSubtle)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.6)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * CGFloat(min(totalWeight / carryLimit, 1.0)),
                            height: 8
                        )
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: totalWeight)
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(Color.spaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Equipment Section

private struct EquipmentSection: View {
    let type: String
    let items: [(index: Int, item: CBEquipment)]
    let onToggle: (Int) -> Void

    var sectionTitle: String {
        switch type {
        case "weapon":     return "Weapons"
        case "armor":      return "Armor & Clothing"
        case "gear":       return "Gear"
        case "consumable": return "Consumables"
        default:           return type.capitalized
        }
    }

    var sectionIcon: String {
        switch type {
        case "weapon":     return "scope"
        case "armor":      return "shield.fill"
        case "gear":       return "backpack.fill"
        case "consumable": return "cross.vial.fill"
        default:           return "cube.fill"
        }
    }

    var sectionColor: Color {
        switch type {
        case "weapon":     return .voidRed
        case "armor":      return .veilGold
        case "gear":       return .veilPurple
        case "consumable": return .veilGlow
        default:           return .mutedText
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Label(sectionTitle, systemImage: sectionIcon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(sectionColor)

            ForEach(items, id: \.index) { indexedItem in
                EquipmentRow(
                    item: indexedItem.item,
                    accentColor: sectionColor
                )
                .onTapGesture { onToggle(indexedItem.index) }
            }
        }
    }
}

// MARK: - Equipment Row

private struct EquipmentRow: View {
    let item: CBEquipment
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            // Toggle checkbox
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(item.isSelected ? accentColor.opacity(0.2) : Color.borderSubtle.opacity(0.4))
                    .frame(width: 28, height: 28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(item.isSelected ? accentColor : Color.borderSubtle, lineWidth: 1.5)
                    )
                if item.isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(accentColor)
                }
            }

            // Item icon
            Image(systemName: item.typeIcon)
                .font(.body)
                .foregroundStyle(item.isSelected ? accentColor : Color.mutedText)
                .frame(width: 24)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(item.isSelected ? Color.lightText : Color.mutedText)

                    Spacer()

                    // Weight badge
                    Text(item.encumbranceLabel)
                        .font(.caption2.weight(.medium).monospacedDigit())
                        .foregroundStyle(Color.mutedText)
                }

                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(Color.mutedText.opacity(0.7))
                    .lineLimit(1)

                if item.isDefault {
                    Text("Default gear")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.veilGlow.opacity(0.7))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.spaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            item.isSelected ? accentColor.opacity(0.5) : Color.borderSubtle,
                            lineWidth: item.isSelected ? 1.5 : 1
                        )
                )
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: item.isSelected)
    }
}

// MARK: - Preview

#Preview("Equipment Select") {
    let vm = CharacterBuilderViewModel()
    vm.draft.charClass = CBClass.samples.first(where: { $0.name == "Tidecaller" })
    vm.draft.selectedEquipment = CBEquipment.samples(forClass: "Tidecaller")
    return EquipmentSelectView(vm: vm)
        .preferredColorScheme(.dark)
        .background(Color.spacePrimary)
}
