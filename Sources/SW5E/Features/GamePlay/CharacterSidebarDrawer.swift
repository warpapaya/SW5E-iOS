import SwiftUI

/// Swipe-from-right drawer showing live character stats during gameplay.
struct CharacterSidebarDrawer: View {
    // Campaign is now a plain struct — no ObservableObject
    let campaign: Campaign
    @Binding var isPresented: Bool
    let character: Character?

    @State private var selectedPowerIndex: Int? = nil
    @State private var showInventory = false

    var characterName:  String { character?.name     ?? "Unknown" }
    var characterClass: String { character?.charClass ?? "N/A" }
    var level:          Int    { character?.level     ?? 1 }

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .trailing) {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) { isPresented = false }
                    }

                VStack(spacing: 0) {
                    drawerHeader
                    Divider().background(Color.borderSubtle)

                    ScrollViewShowsIndicators {
                        VStack(spacing: 0) {
                            hpStatusSection
                            Divider().background(Color.borderSubtle)
                            powersSection
                            Divider().background(Color.borderSubtle)
                            quickInventorySection
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .background(Color.spacePrimary)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }

    // MARK: - Drawer Header

    @ViewBuilder private var drawerHeader: some View {
        HStack(spacing: 12) {
            Text("Character")
                .font(.holoDisplay)
                .foregroundColor(.hologramBlue)
            Spacer()
            Button(action: { withAnimation(.easeOut(duration: 0.2)) { isPresented = false } }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.mutedText)
                    .font(.system(size: 28))
            }
        }
        .padding(16)
    }

    // MARK: - HP & Status Section

    @ViewBuilder private var hpStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("STATUS")
                .font(.dataReadout)
                .foregroundColor(.hologramBlue)
                .padding(.horizontal, 16)

            HStack(spacing: 8) {
                Image(systemName: "person.fill").foregroundColor(.lightText)
                VStack(alignment: .leading, spacing: 2) {
                    Text(characterName).font(.bodyText).foregroundColor(.lightText)
                    HStack(spacing: 4) {
                        Text(characterClass).font(.dataReadout).foregroundColor(.hologramBlue)
                        Circle().fill(Color.holoBlueSubtle).frame(width: 4, height: 4)
                        Text("Level \(level)").font(.dataReadout).foregroundColor(.lightText)
                    }
                }
            }
            .padding(.horizontal, 16)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hit Points").font(.dataReadout).foregroundColor(.lightText)
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill").foregroundColor(.siithRed)
                        Text("\(characterHP)/\(characterMaxHP)")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.lightText)
                    }
                }
                Spacer()
                VStack(spacing: 8) {
                    statBadge(icon: "shield.fill",   label: "AC",   value: "\(characterAC)")
                    statBadge(icon: "arrow.up.right", label: "Init", value: "\(characterInitiative)")
                }
            }
            .padding(.horizontal, 16)

            HPBar(currentHp: characterHP, maxHp: characterMaxHP, size: 12)
                .padding(.horizontal, 16)
                .padding(.top, 8)
        }
    }

    // MARK: - Powers Section

    @ViewBuilder private var powersSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("POWERS")
                .font(.dataReadout)
                .foregroundColor(.hologramBlue)
                .padding(.horizontal, 16)

            ScrollViewShowsIndicators {
                VStack(spacing: 8) {
                    ForEach(Array(powers.enumerated()), id: \.offset) { index, power in
                        powerButton(power: power, isSelected: selectedPowerIndex == index) {
                            selectPower(index)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Quick Inventory Section

    @ViewBuilder private var quickInventorySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showInventory.toggle() } }) {
                HStack(spacing: 8) {
                    Image(systemName: showInventory ? "chevron.up" : "chevron.down")
                    Text("Quick Inventory").font(.dataReadout).foregroundColor(.lightText)
                    Spacer()
                    Text("\(quickInventoryItems.count)")
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color.spaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding(16)
            }

            if showInventory {
                Divider().background(Color.borderSubtle)
                ScrollViewShowsIndicators {
                    VStack(spacing: 8) {
                        ForEach(quickInventoryItems, id: \.self) { item in
                            inventoryItemRow(item: item)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var characterHP:         Int { character?.currentHP ?? 0 }
    private var characterMaxHP:      Int { character?.maxHP ?? 10 }
    private var characterAC:         Int { character?.ac ?? 10 }
    private var characterInitiative: Int { character?.initiativeBonus ?? 0 }

    private var powers: [Power] {
        [
            Power(name: "Force Push",       description: "Push enemy back 10ft",         type: .force),
            Power(name: "Veilblade Strike", description: "+3 to hit, 1d8+2 damage",      type: .weapon),
            Power(name: "Defensive Stance",  description: "+2 AC until end of turn",      type: .defensive)
        ]
    }

    private var quickInventoryItems: [String] { ["Medpac (2)", "Grenade", "Comlink", "Rations"] }

    // MARK: - Helper Views

    @ViewBuilder private func statBadge(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(.lightText)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.dataReadout).foregroundColor(.mutedText)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.lightText)
            }
        }
    }

    @ViewBuilder private func powerButton(power: Power, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: powerIcon(for: power.type))
                    .foregroundColor(powerColor(for: power.type))
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 4) {
                    Text(power.name)
                        .font(.bodyText)
                        .foregroundColor(isSelected ? Color.hologramBlue : .lightText)
                    Text(power.description)
                        .font(.dataReadout)
                        .foregroundColor(.mutedText)
                }

                Spacer()
                Circle()
                    .fill(isSelected ? Color.hologramBlue : Color.borderSubtle)
                    .frame(width: 12, height: 12)
            }
            .padding(12)
            .background(isSelected ? Color.spaceCard.opacity(0.7) : Color.spaceCard.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder private func inventoryItemRow(item: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "box.fill").foregroundColor(.lightText)
            Text(item).font(.bodyText).foregroundColor(.lightText)
            Spacer()
            Button(action: { useItem(item) }) {
                Image(systemName: "checkmark.circle").foregroundColor(.saberGreen)
            }
        }
        .padding(12)
        .background(Color.spaceCard.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Helpers

    private func powerIcon(for type: PowerType) -> String {
        switch type {
        case .force:     return "sparkles"
        case .weapon:    return "scope"
        case .defensive: return "shield.fill"
        }
    }

    private func powerColor(for type: PowerType) -> Color {
        switch type {
        case .force:     return .hologramBlue
        case .weapon:    return .techOrange
        case .defensive: return .saberGreen
        }
    }

    private func selectPower(_ index: Int) {
        selectedPowerIndex = index
        print("Power selected: \(powers[index].name)")
        withAnimation(.easeOut(duration: 0.2)) { selectedPowerIndex = nil }
    }

    private func useItem(_ item: String) {
        print("Using item: \(item)")
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Power Model

enum PowerType {
    case force, weapon, defensive
}

struct Power: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var description: String
    var type: PowerType

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Power, rhs: Power) -> Bool { lhs.id == rhs.id }
}

// MARK: - Preview

#Preview("Character Sidebar Drawer") {
    struct Wrapper: View {
        @State private var showDrawer = true
        var body: some View {
            ZStack(alignment: .trailing) {
                Color.spacePrimary.ignoresSafeArea()
                CharacterSidebarDrawer(
                    campaign: Campaign(id: "test", title: "Test", currentLocation: "Solara Prime", gameState: .init()),
                    isPresented: $showDrawer,
                    character: Character(
                        id: "preview-1",
                        name: "Jax Varrick",
                        species: "Human",
                        charClass: "Tidecaller",
                        level: 5,
                        experiencePoints: 0,
                        currentHP: 28,
                        maxHP: 35,
                        ac: 16,
                        forcePoints: 5,
                        lastModified: Date()
                    )
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }
    return Wrapper()
}
