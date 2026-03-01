import SwiftUI

// MARK: - Extended Character Models

/// Full ability scores for the character sheet
struct CSAbilityScores: Codable, Equatable {
    var strength: Int     = 10
    var dexterity: Int    = 10
    var constitution: Int = 10
    var intelligence: Int = 10
    var wisdom: Int       = 10
    var charisma: Int     = 10

    func score(for key: String) -> Int {
        switch key {
        case "STR": return strength
        case "DEX": return dexterity
        case "CON": return constitution
        case "INT": return intelligence
        case "WIS": return wisdom
        case "CHA": return charisma
        default:    return 10
        }
    }

    static func modifier(for score: Int) -> Int { (score - 10) / 2 }

    var strMod: Int { CSAbilityScores.modifier(for: strength) }
    var dexMod: Int { CSAbilityScores.modifier(for: dexterity) }
    var conMod: Int { CSAbilityScores.modifier(for: constitution) }
    var intMod: Int { CSAbilityScores.modifier(for: intelligence) }
    var wisMod: Int { CSAbilityScores.modifier(for: wisdom) }
    var chaMod: Int { CSAbilityScores.modifier(for: charisma) }

    enum CodingKeys: String, CodingKey {
        case strength, dexterity, constitution, intelligence, wisdom, charisma
    }
}

/// Derivation formula shown on long-press tooltip
enum StatFormula {
    case ability(name: String, score: Int)
    case derived(name: String, formula: String)

    var description: String {
        switch self {
        case let .ability(name, score):
            let mod = CSAbilityScores.modifier(for: score)
            let sign = mod >= 0 ? "+" : ""
            return "\(name) \(score) → modifier = (\(score) − 10) ÷ 2 = \(sign)\(mod)"
        case let .derived(name, formula):
            return "\(name): \(formula)"
        }
    }
}

/// Single skill entry
struct SkillEntry: Identifiable {
    let id = UUID()
    let name: String
    let ability: String   // STR/DEX/CON/INT/WIS/CHA
    var isProficient: Bool
    var hasExpertise: Bool = false
    let abilityMod: Int
    let proficiencyBonus: Int

    var total: Int {
        let prof = isProficient ? (hasExpertise ? proficiencyBonus * 2 : proficiencyBonus) : 0
        return abilityMod + prof
    }

    var formula: String {
        let base = "\(ability) mod (\(abilityMod >= 0 ? "+" : "")\(abilityMod))"
        if isProficient {
            let extra = hasExpertise ? "expertise ×2" : "proficiency"
            return "\(base) + \(extra) (+\(proficiencyBonus))"
        }
        return base
    }
}

/// Character power (force / tech)
struct CharacterPower: Identifiable, Codable {
    var id: String      = UUID().uuidString
    var name: String
    var level: Int
    var castingTime: String
    var duration: String
    var powerType: String   // "force" | "tech"
    var description: String
}

/// Weapon or armor or gear
struct EquipmentItem: Identifiable, Codable {
    var id: String      = UUID().uuidString
    var name: String
    var type: String            // "weapon" | "armor" | "gear"
    var attackBonus: Int?
    var damageDice: String?
    var damageType: String?
    var armorClass: Int?
    var quantity: Int           = 1
    var weight: Double          = 1.0
    var equipped: Bool          = true
}

/// Class / background / species feature
struct CharacterFeature: Identifiable, Codable {
    var id: String  = UUID().uuidString
    var name: String
    var source: String          // "class" | "background" | "species"
    var description: String
}

// MARK: - XP Tables

private let xpThresholds: [Int: Int] = [
    1: 300, 2: 900, 3: 2_700, 4: 6_500, 5: 14_000,
    6: 23_000, 7: 34_000, 8: 48_000, 9: 64_000, 10: 85_000,
    11: 100_000, 12: 120_000, 13: 140_000, 14: 165_000, 15: 195_000,
    16: 225_000, 17: 265_000, 18: 305_000, 19: 355_000
]

private func proficiencyBonus(level: Int) -> Int {
    switch level {
    case 1...4:  return 2
    case 5...8:  return 3
    case 9...12: return 4
    case 13...16: return 5
    default:     return 6
    }
}

// MARK: - ViewModel

@MainActor
final class CharacterSheetViewModel: ObservableObject {

    @Published var character: Character
    @Published var abilityScores   = CSAbilityScores()
    @Published var skills: [SkillEntry]   = []
    @Published var powers: [CharacterPower] = []
    @Published var equipment: [EquipmentItem] = []
    @Published var features: [CharacterFeature] = []
    @Published var backstory   = ""
    @Published var notes       = ""

    @Published var isLoading   = false
    @Published var isSavingNotes = false
    @Published var errorMessage: String?

    private let api = APIService.shared
    private var saveNotesTask: Task<Void, Never>?

    init(character: Character) {
        self.character = character
        buildSkills()
        loadDummyData()
    }

    // MARK: Derived

    var profBonus: Int { proficiencyBonus(level: character.level) }

    var xpForNextLevel: Int? { xpThresholds[character.level] }

    var canLevelUp: Bool {
        guard let threshold = xpForNextLevel else { return false }
        return character.experiencePoints >= threshold
    }

    var speed: Int {
        // Species-based base; stub
        character.species.lowercased().contains("wookiee") ? 30 : 30
    }

    var initiative: Int { abilityScores.dexMod }

    // MARK: Skills Build

    private let skillDefinitions: [(String, String)] = [
        ("Acrobatics", "DEX"), ("Animal Handling", "WIS"), ("Athletics", "STR"),
        ("Deception", "CHA"), ("History", "INT"), ("Insight", "WIS"),
        ("Intimidation", "CHA"), ("Investigation", "INT"), ("Lore", "INT"),
        ("Medicine", "WIS"), ("Nature", "INT"), ("Perception", "WIS"),
        ("Performance", "CHA"), ("Persuasion", "CHA"), ("Piloting", "DEX"),
        ("Sleight of Hand", "DEX"), ("Stealth", "DEX"), ("Survival", "WIS")
    ]

    private func abilityMod(for key: String) -> Int {
        CSAbilityScores.modifier(for: abilityScores.score(for: key))
    }

    func buildSkills() {
        skills = skillDefinitions.map { name, ability in
            SkillEntry(
                name: name,
                ability: ability,
                isProficient: false,
                abilityMod: abilityMod(for: ability),
                proficiencyBonus: profBonus
            )
        }.sorted { $0.total > $1.total }
    }

    // MARK: Load

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fresh = try await api.fetchCharacter(id: character.id)
            character = fresh
        } catch {
            // Offline / stub — keep current data
        }
        buildSkills()
    }

    // MARK: HP Mutation

    func setCurrentHP(_ value: Int) {
        character.currentHP = max(0, min(character.maxHP, value))
    }

    // MARK: Notes Auto-Save

    func scheduleNotesSave() {
        saveNotesTask?.cancel()
        saveNotesTask = Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            await patchNotes()
        }
    }

    private func patchNotes() async {
        isSavingNotes = true
        defer { isSavingNotes = false }
        // PATCH /api/characters/:id  { notes, backstory }
        let url = URL(string: "\(api.serverURL)/api/characters/\(character.id)")!
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["notes": notes, "backstory": backstory]
        req.httpBody = try? JSONEncoder().encode(body)
        _ = try? await URLSession.shared.data(for: req)
    }

    // MARK: Stub Data

    private func loadDummyData() {
        abilityScores = CSAbilityScores(
            strength: 14, dexterity: 16, constitution: 13,
            intelligence: 10, wisdom: 12, charisma: 10
        )
        buildSkills()

        powers = [
            CharacterPower(name: "Force Push",    level: 1, castingTime: "1 action", duration: "Instantaneous", powerType: "force", description: "Push a target 10 ft away."),
            CharacterPower(name: "Sense Force",   level: 0, castingTime: "1 action", duration: "Concentration, up to 10 min", powerType: "force", description: "Sense presences strong in the Force."),
            CharacterPower(name: "Force Barrier",  level: 2, castingTime: "1 reaction", duration: "1 round", powerType: "force", description: "Add +5 to AC against one attack."),
        ]

        equipment = [
            EquipmentItem(name: "Veilblade",   type: "weapon", attackBonus: 5, damageDice: "1d8+3", damageType: "energy", weight: 1.0),
            EquipmentItem(name: "Light Armor",  type: "armor",  armorClass: 13, weight: 10.0),
            EquipmentItem(name: "Comlink",      type: "gear",   quantity: 1,    weight: 0.5),
            EquipmentItem(name: "Medpac",       type: "gear",   quantity: 3,    weight: 0.5),
        ]

        features = [
            CharacterFeature(name: "Forcecasting",          source: "class",      description: "Use the Force to cast powers. Force Points equal to your level × WIS modifier."),
            CharacterFeature(name: "Combat Superiority",    source: "class",      description: "Gain 4 superiority dice (d8) for maneuvers per short rest."),
            CharacterFeature(name: "Scholarly Background",  source: "background", description: "Proficiency in History and Lore. Speak two extra languages."),
            CharacterFeature(name: "Human Versatility",     source: "species",    description: "+1 to any two ability scores. Gain proficiency in one additional skill."),
        ]

        backstory = character.name.isEmpty ? "" : "A wandering \(character.species) \(character.charClass) seeking their place in a galaxy far, far away."
    }
}

// MARK: - Main Sheet View

struct CharacterSheetView: View {

    @StateObject private var vm: CharacterSheetViewModel
    @State private var selectedTab: SheetTab = .skills
    @State private var showingHPEditor    = false
    @State private var showingLevelUp     = false
    @State private var showingCampaignPick = false
    @State private var tooltipFormula: StatFormula?

    enum SheetTab: String, CaseIterable {
        case skills    = "Skills"
        case powers    = "Powers"
        case equipment = "Equipment"
        case features  = "Features"
        case notes     = "Notes"
    }

    init(character: Character) {
        _vm = StateObject(wrappedValue: CharacterSheetViewModel(character: character))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // ── Background ──
            Color.spacePrimary.ignoresSafeArea()

            // ── Scrollable content ──
            ScrollView {
                VStack(spacing: 0) {
                    CharacterHeaderSection(vm: vm, showingLevelUp: $showingLevelUp)
                    VitalsBarSection(vm: vm, showingHPEditor: $showingHPEditor)
                        .padding(.top, 16)
                    AbilityScoresSection(vm: vm, tooltipFormula: $tooltipFormula)
                        .padding(.top, 16)
                    TabPickerBar(selected: $selectedTab)
                        .padding(.top, 16)
                    tabContent
                        .padding(.top, 8)
                }
                .padding(.bottom, 100) // space for FAB
            }

            // ── Play FAB ──
            playFAB
                .padding(.trailing, 20)
                .padding(.bottom, 28)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(vm.character.name)
        .task { await vm.load() }
        // ── Sheets ──
        .sheet(isPresented: $showingHPEditor) {
            HPEditorSheet(vm: vm)
                .presentationDetents([.height(300)])
        }
        .sheet(isPresented: $showingLevelUp) {
            LevelUpSheet(character: vm.character)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingCampaignPick) {
            CampaignSelectStub(character: vm.character)
                .presentationDetents([.large])
        }
        // ── Tooltip overlay ──
        .overlay {
            if let formula = tooltipFormula {
                StatTooltipOverlay(formula: formula) {
                    tooltipFormula = nil
                }
            }
        }
    }

    // MARK: Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .skills:
            SkillsTabView(vm: vm, tooltipFormula: $tooltipFormula)
        case .powers:
            PowersTabView(vm: vm)
        case .equipment:
            EquipmentTabView(vm: vm)
        case .features:
            FeaturesTabView(vm: vm)
        case .notes:
            NotesTabView(vm: vm)
        }
    }

    // MARK: FAB

    private var playFAB: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showingCampaignPick = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                Text("Play")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(Color.hologramBlue)
            )
            .shadow(color: .hologramBlue.opacity(0.6), radius: 14, x: 0, y: 6)
        }
    }
}

// MARK: - Header Section

private struct CharacterHeaderSection: View {
    @ObservedObject var vm: CharacterSheetViewModel
    @Binding var showingLevelUp: Bool

    private var classColor: CharacterClassColor {
        CharacterClassColor(rawValue: vm.character.charClass) ?? .guardian
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                // Portrait
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [classColor.gradientColors.0, classColor.gradientColors.1],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: classColor.gradientColors.0.opacity(0.5), radius: 10)

                    Image(systemName: classColor.icon)
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }

                // Name / subline
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(vm.character.name)
                            .font(.title2.weight(.bold))
                            .foregroundColor(.lightText)

                        // Level badge
                        Text("LVL \(vm.character.level)")
                            .font(.caption.weight(.heavy))
                            .foregroundColor(.spacePrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.hologramBlue))
                    }

                    Text("\(vm.character.species) · \(vm.character.charClass)")
                        .font(.subheadline)
                        .foregroundColor(.mutedText)

                    // XP bar
                    xpBar

                    // Level-up button
                    if vm.canLevelUp {
                        Button {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            showingLevelUp = true
                        } label: {
                            Label("Level Up!", systemImage: "arrow.up.circle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.spacePrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.saberGreen))
                                .shadow(color: .saberGreen.opacity(0.5), radius: 6)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var xpBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("XP: \(vm.character.experiencePoints)")
                    .font(.caption)
                    .foregroundColor(.mutedText)
                if let threshold = vm.xpForNextLevel {
                    Text("/ \(threshold)")
                        .font(.caption)
                        .foregroundColor(.mutedText)
                }
            }
            if let threshold = vm.xpForNextLevel {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.borderSubtle)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.hologramBlue)
                            .frame(width: geo.size.width * min(1, Double(vm.character.experiencePoints) / Double(threshold)))
                    }
                }
                .frame(height: 6)
            }
        }
    }
}

// MARK: - Vitals Bar

private struct VitalsBarSection: View {
    @ObservedObject var vm: CharacterSheetViewModel
    @Binding var showingHPEditor: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // HP — tappable
                Button { showingHPEditor = true } label: {
                    VitalBadge(label: "HP", value: "\(vm.character.currentHP)/\(vm.character.maxHP)", color: hpColor, icon: "heart.fill")
                }
                .buttonStyle(.plain)

                VitalBadge(label: "AC", value: "\(vm.character.ac)", color: .hologramBlue, icon: "shield.fill")
                VitalBadge(label: "Init", value: (vm.initiative >= 0 ? "+\(vm.initiative)" : "\(vm.initiative)"), color: .techOrange, icon: "bolt.fill")
                VitalBadge(label: "Speed", value: "\(vm.speed) ft", color: .saberGreen, icon: "figure.walk")
                VitalBadge(label: "Prof", value: "+\(vm.profBonus)", color: .hologramBlue, icon: "star.fill")
                if vm.character.forcePoints > 0 {
                    VitalBadge(label: "VP", value: "\(vm.character.forcePoints)", color: .siithRed, icon: "moon.stars.fill")
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var hpColor: Color {
        let pct = vm.character.hpPercentage
        if pct < 0.25 { return .siithRed }
        if pct < 0.5  { return .techOrange }
        return .saberGreen
    }
}

private struct VitalBadge: View {
    let label: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text(value)
                .font(.system(.subheadline, design: .monospaced).weight(.bold))
                .foregroundColor(.lightText)
            Text(label)
                .font(.caption2)
                .foregroundColor(.mutedText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.spaceCard)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.3), lineWidth: 1))
        )
        .shadow(color: color.opacity(0.15), radius: 4)
    }
}

// MARK: - Ability Scores Grid

private struct AbilityScoresSection: View {
    @ObservedObject var vm: CharacterSheetViewModel
    @Binding var tooltipFormula: StatFormula?

    private let abilities: [(String, KeyPath<CSAbilityScores, Int>)] = [
        ("STR", \.strength), ("DEX", \.dexterity), ("CON", \.constitution),
        ("INT", \.intelligence), ("WIS", \.wisdom), ("CHA", \.charisma)
    ]

    private let abilityFullNames: [String: String] = [
        "STR": "Strength", "DEX": "Dexterity", "CON": "Constitution",
        "INT": "Intelligence", "WIS": "Wisdom", "CHA": "Charisma"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(title: "ABILITY SCORES")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(abilities, id: \.0) { key, path in
                    let score = vm.abilityScores[keyPath: path]
                    let mod   = CSAbilityScores.modifier(for: score)
                    AbilityScoreBadge(key: key, score: score, modifier: mod)
                        .onLongPressGesture(minimumDuration: 0.4) {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            tooltipFormula = .ability(name: abilityFullNames[key] ?? key, score: score)
                        }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

private struct AbilityScoreBadge: View {
    let key: String
    let score: Int
    let modifier: Int

    private var color: Color {
        switch key {
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
        VStack(spacing: 6) {
            Text(key)
                .font(.caption2.weight(.heavy))
                .foregroundColor(.mutedText)
                .tracking(1)
            Text("\(score)")
                .font(.title2.weight(.bold))
                .foregroundColor(.lightText)
            Text(modifier >= 0 ? "+\(modifier)" : "\(modifier)")
                .font(.caption.weight(.semibold))
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Capsule().fill(color.opacity(0.15)))
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.spaceCard)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.25), lineWidth: 1))
        )
    }
}

// MARK: - Tab Picker Bar

private struct TabPickerBar: View {
    @Binding var selected: CharacterSheetView.SheetTab

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(CharacterSheetView.SheetTab.allCases, id: \.self) { tab in
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        withAnimation(.spring(response: 0.3)) { selected = tab }
                    } label: {
                        Text(tab.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(selected == tab ? .spacePrimary : .mutedText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(selected == tab ? Color.hologramBlue : Color.spaceCard)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Skills Tab

private struct SkillsTabView: View {
    @ObservedObject var vm: CharacterSheetViewModel
    @Binding var tooltipFormula: StatFormula?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(vm.skills) { skill in
                SkillRow(skill: skill)
                    .onLongPressGesture(minimumDuration: 0.4) {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        tooltipFormula = .derived(name: skill.name, formula: skill.formula)
                    }
                Divider().background(Color.borderSubtle).padding(.leading, 16)
            }
        }
        .background(Color.spaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
}

private struct SkillRow: View {
    let skill: SkillEntry

    var body: some View {
        HStack(spacing: 12) {
            // Proficiency dot
            Circle()
                .fill(skill.isProficient ? Color.hologramBlue : Color.borderSubtle)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.hologramBlue, lineWidth: skill.hasExpertise ? 2 : 0)
                        .frame(width: 12, height: 12)
                )

            Text(skill.name)
                .font(.subheadline)
                .foregroundColor(.lightText)

            Spacer()

            Text(skill.ability)
                .font(.caption2.weight(.medium))
                .foregroundColor(.mutedText)
                .frame(width: 28)

            // Highlight proficient skills
            Text(skill.total >= 0 ? "+\(skill.total)" : "\(skill.total)")
                .font(.system(.subheadline, design: .monospaced).weight(.bold))
                .foregroundColor(skill.isProficient ? .hologramBlue : .lightText)
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - Powers Tab

private struct PowersTabView: View {
    @ObservedObject var vm: CharacterSheetViewModel

    private var grouped: [(Int, [CharacterPower])] {
        let levels = Set(vm.powers.map(\.level)).sorted()
        return levels.map { lvl in (lvl, vm.powers.filter { $0.level == lvl }) }
    }

    var body: some View {
        if vm.powers.isEmpty {
            EmptyTabPlaceholder(icon: "wand.and.stars", message: "No powers known")
        } else {
            VStack(spacing: 16) {
                ForEach(grouped, id: \.0) { level, powers in
                    VStack(alignment: .leading, spacing: 0) {
                        SectionLabel(title: level == 0 ? "CANTRIPS" : "LEVEL \(level)")
                            .padding(.horizontal, 16)
                            .padding(.bottom, 4)

                        VStack(spacing: 0) {
                            ForEach(powers) { power in
                                PowerRow(power: power)
                                if power.id != powers.last?.id {
                                    Divider().background(Color.borderSubtle).padding(.leading, 16)
                                }
                            }
                        }
                        .background(Color.spaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct PowerRow: View {
    let power: CharacterPower
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                UISelectionFeedbackGenerator().selectionChanged()
                withAnimation(.spring(response: 0.3)) { expanded.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(power.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.lightText)
                        HStack(spacing: 8) {
                            Label(power.castingTime, systemImage: "timer")
                                .font(.caption2)
                                .foregroundColor(.mutedText)
                            Label(power.duration, systemImage: "clock")
                                .font(.caption2)
                                .foregroundColor(.mutedText)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.mutedText)
                        .rotationEffect(expanded ? .degrees(90) : .zero)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if expanded {
                Text(power.description)
                    .font(.footnote)
                    .foregroundColor(.mutedText)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
    }
}

// MARK: - Equipment Tab

private struct EquipmentTabView: View {
    @ObservedObject var vm: CharacterSheetViewModel

    private var totalWeight: Double { vm.equipment.reduce(0) { $0 + $1.weight * Double($1.quantity) } }

    var body: some View {
        if vm.equipment.isEmpty {
            EmptyTabPlaceholder(icon: "backpack", message: "No equipment")
        } else {
            VStack(alignment: .leading, spacing: 12) {
                // Encumbrance
                HStack {
                    Image(systemName: "scalemass")
                        .foregroundColor(.mutedText)
                    Text("Total weight: \(String(format: "%.1f", totalWeight)) lb")
                        .font(.caption)
                        .foregroundColor(.mutedText)
                    Spacer()
                    let strength = vm.abilityScores.strength
                    Text("Carry cap: \(strength * 15) lb")
                        .font(.caption)
                        .foregroundColor(.mutedText)
                }
                .padding(.horizontal, 16)

                ForEach(["weapon", "armor", "gear"], id: \.self) { type in
                    let items = vm.equipment.filter { $0.type == type }
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            SectionLabel(title: type.uppercased() + "S")
                                .padding(.horizontal, 16).padding(.bottom, 4)
                            VStack(spacing: 0) {
                                ForEach(items) { item in
                                    EquipmentRow(item: item)
                                    if item.id != items.last?.id {
                                        Divider().background(Color.borderSubtle).padding(.leading, 16)
                                    }
                                }
                            }
                            .background(Color.spaceCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct EquipmentRow: View {
    let item: EquipmentItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.type == "weapon" ? "sword.fill" :
                             item.type == "armor"  ? "shield.fill" : "bag.fill")
                .font(.caption)
                .foregroundColor(item.type == "weapon" ? .siithRed :
                                 item.type == "armor"  ? .hologramBlue : .mutedText)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .foregroundColor(.lightText)

                if item.type == "weapon", let atk = item.attackBonus, let dmg = item.damageDice {
                    Text("+\(atk) to hit · \(dmg) \(item.damageType ?? "dmg")")
                        .font(.caption2)
                        .foregroundColor(.techOrange)
                } else if item.type == "armor", let ac = item.armorClass {
                    Text("AC \(ac)")
                        .font(.caption2)
                        .foregroundColor(.hologramBlue)
                } else if item.quantity > 1 {
                    Text("×\(item.quantity)")
                        .font(.caption2)
                        .foregroundColor(.mutedText)
                }
            }

            Spacer()

            Text("\(String(format: "%.1f", item.weight)) lb")
                .font(.caption2)
                .foregroundColor(.mutedText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Features Tab

private struct FeaturesTabView: View {
    @ObservedObject var vm: CharacterSheetViewModel

    private let sourceOrder = ["class", "background", "species"]

    var body: some View {
        if vm.features.isEmpty {
            EmptyTabPlaceholder(icon: "sparkles", message: "No features")
        } else {
            VStack(spacing: 16) {
                ForEach(sourceOrder, id: \.self) { source in
                    let items = vm.features.filter { $0.source == source }
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            SectionLabel(title: source.uppercased() + " FEATURES")
                                .padding(.horizontal, 16).padding(.bottom, 4)
                            VStack(spacing: 0) {
                                ForEach(items) { feature in
                                    FeatureRow(feature: feature)
                                    if feature.id != items.last?.id {
                                        Divider().background(Color.borderSubtle).padding(.leading, 16)
                                    }
                                }
                            }
                            .background(Color.spaceCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct FeatureRow: View {
    let feature: CharacterFeature
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                UISelectionFeedbackGenerator().selectionChanged()
                withAnimation(.spring(response: 0.3)) { expanded.toggle() }
            } label: {
                HStack {
                    Text(feature.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.lightText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.mutedText)
                        .rotationEffect(expanded ? .degrees(90) : .zero)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if expanded {
                Text(feature.description)
                    .font(.footnote)
                    .foregroundColor(.mutedText)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
    }
}

// MARK: - Notes Tab

private struct NotesTabView: View {
    @ObservedObject var vm: CharacterSheetViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Backstory
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(title: "BACKSTORY")
                TextEditor(text: $vm.backstory)
                    .font(.footnote)
                    .foregroundColor(.lightText)
                    .scrollContentBackground(.hidden)
                    .background(Color.spaceCard)
                    .frame(minHeight: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.borderSubtle, lineWidth: 1))
                    .onChange(of: vm.backstory) { _, _ in vm.scheduleNotesSave() }
            }

            // Free-form notes
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SectionLabel(title: "NOTES")
                    Spacer()
                    if vm.isSavingNotes {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.saberGreen.opacity(0.7))
                    }
                }
                TextEditor(text: $vm.notes)
                    .font(.footnote)
                    .foregroundColor(.lightText)
                    .scrollContentBackground(.hidden)
                    .background(Color.spaceCard)
                    .frame(minHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.borderSubtle, lineWidth: 1))
                    .onChange(of: vm.notes) { _, _ in vm.scheduleNotesSave() }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - HP Editor Sheet

private struct HPEditorSheet: View {
    @ObservedObject var vm: CharacterSheetViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Current HP large display
                Text("\(vm.character.currentHP) / \(vm.character.maxHP)")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.lightText)

                HPBar(current: vm.character.currentHP, maximum: vm.character.maxHP)
                    .frame(height: 20)
                    .padding(.horizontal, 32)

                // Stepper
                HStack(spacing: 20) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        vm.setCurrentHP(vm.character.currentHP - 1)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.siithRed)
                    }

                    TextField("HP", text: $inputText)
                        .font(.title.weight(.semibold).monospacedDigit())
                        .foregroundColor(.lightText)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .frame(width: 80)
                        .focused($focused)
                        .onChange(of: inputText) { _, v in
                            if let n = Int(v) { vm.setCurrentHP(n) }
                        }

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        vm.setCurrentHP(vm.character.currentHP + 1)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.saberGreen)
                    }
                }

                HStack(spacing: 12) {
                    HPQuickButton(label: "Heal +5", delta: 5, color: .saberGreen) { vm.setCurrentHP(vm.character.currentHP + 5) }
                    HPQuickButton(label: "Full", delta: 0, color: .hologramBlue) { vm.setCurrentHP(vm.character.maxHP) }
                    HPQuickButton(label: "Damage -5", delta: -5, color: .siithRed) { vm.setCurrentHP(vm.character.currentHP - 5) }
                }
            }
            .padding(24)
            .background(Color.spacePrimary)
            .navigationTitle("Edit HP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundColor(.hologramBlue)
                }
            }
            .onAppear {
                inputText = "\(vm.character.currentHP)"
                focused = true
            }
        }
        .background(Color.spacePrimary)
    }
}

private struct HPQuickButton: View {
    let label: String
    let delta: Int
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: { UIImpactFeedbackGenerator(style: .medium).impactOccurred(); action() }) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(color)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.15)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Level Up Sheet (stub)

private struct LevelUpSheet: View {
    let character: Character
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.saberGreen)
                    .shadow(color: .saberGreen.opacity(0.6), radius: 16)

                Text("Level Up!")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.lightText)

                Text("Advance \(character.name) to Level \(character.level + 1)")
                    .font(.subheadline)
                    .foregroundColor(.mutedText)
                    .multilineTextAlignment(.center)

                Text("Full level-up flow coming soon")
                    .font(.footnote)
                    .foregroundColor(.mutedText)
                    .italic()
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.spacePrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.foregroundColor(.hologramBlue)
                }
            }
        }
    }
}

// MARK: - Campaign Select Stub

/// Stub shown until CampaignSelectView is implemented; navigates with pre-loaded character
private struct CampaignSelectStub: View {
    let character: Character
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.hologramBlue)
                    .shadow(color: .hologramBlue.opacity(0.5), radius: 12)

                Text("Play as \(character.name)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.lightText)

                Text("Select or start a campaign\n(Campaign select view coming soon)")
                    .font(.subheadline)
                    .foregroundColor(.mutedText)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.spacePrimary)
            .navigationTitle("Choose Campaign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.hologramBlue)
                }
            }
        }
    }
}

// MARK: - Stat Tooltip Overlay

private struct StatTooltipOverlay: View {
    let formula: StatFormula
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "function")
                        .foregroundColor(.hologramBlue)
                    Text("Derived Formula")
                        .font(.headline)
                        .foregroundColor(.lightText)
                    Spacer()
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.mutedText)
                    }
                }
                Text(formula.description)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.saberGreen)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .background(Color.spaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.hologramBlue.opacity(0.4), lineWidth: 1))
            .shadow(color: .hologramBlue.opacity(0.2), radius: 20)
            .padding(.horizontal, 24)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - Shared Helpers

private struct SectionLabel: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.caption2.weight(.heavy))
            .foregroundColor(.mutedText)
            .tracking(1.5)
    }
}

private struct EmptyTabPlaceholder: View {
    let icon: String
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.mutedText)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Previews

#Preview("Character Sheet") {
    NavigationStack {
        CharacterSheetView(character: .default)
    }
    .preferredColorScheme(.dark)
}

#Preview("HP Editor") {
    HPEditorSheet(vm: CharacterSheetViewModel(character: .default))
}

#Preview("Ability Scores") {
    AbilityScoresSection(
        vm: CharacterSheetViewModel(character: .default),
        tooltipFormula: .constant(nil)
    )
    .padding()
    .background(Color.spacePrimary)
    .preferredColorScheme(.dark)
}
