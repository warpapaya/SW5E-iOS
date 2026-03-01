import SwiftUI

// MARK: - Species Model

struct CBSpecies: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let traits: [String]
    let abilityBonuses: [String: Int]
    let description: String

    enum CodingKeys: String, CodingKey {
        case id, name, traits, description
        case abilityBonuses = "ability_bonuses"
    }

    static let samples: [CBSpecies] = [
        CBSpecies(id: "arion", name: "Arion",
                  traits: ["Adaptable", "Ambitious", "Extra Skill"],
                  abilityBonuses: ["any": 1],
                  description: "The most widespread species in the galaxy, valued for their ambition and adaptability."),
        CBSpecies(id: "sylari", name: "Sylari",
                  traits: ["Charismatic", "Resonant Crest", "Low-light Vision"],
                  abilityBonuses: ["cha": 2, "dex": 1],
                  description: "Known for their bioluminescent crests and innate charm, Sylari are natural diplomats."),
        CBSpecies(id: "vrask", name: "Vrask",
                  traits: ["Powerful Build", "Natural Claws", "Fury"],
                  abilityBonuses: ["str": 2, "con": 1],
                  description: "Vrask are large, powerful beings covered in banded grey-silver scales. Deep honor culture, fierce warriors, fiercely loyal to those who earn their respect."),
        CBSpecies(id: "mirialan", name: "Mirialan",
                  traits: ["Veilborn", "Focused", "Acrobatic"],
                  abilityBonuses: ["wis": 2, "dex": 1],
                  description: "Naturally attuned to the Veil, Mirialans are disciplined and spiritually aware."),
        CBSpecies(id: "zabrak", name: "Zabrak",
                  traits: ["Determined", "Pain Endurance", "Horns"],
                  abilityBonuses: ["con": 1, "wis": 1],
                  description: "Strong-willed beings known for their horns and resistance to pain."),
        CBSpecies(id: "rodian", name: "Rodian",
                  traits: ["Natural Hunter", "Tracker", "Multi-Directional Eyes"],
                  abilityBonuses: ["dex": 2],
                  description: "Drifborn are those raised on stations and deep-space vessels — culturally stateless, hyper-adaptable, and trusted nowhere and everywhere."),
        CBSpecies(id: "bothan", name: "Bothan",
                  traits: ["Natural Spy", "Intuitive", "Cunning"],
                  abilityBonuses: ["int": 1, "cha": 1],
                  description: "Keth are four-armed, coral-skinned beings known for their methodical thinking and engineering mastery."),
        CBSpecies(id: "togruta", name: "Togruta",
                  traits: ["Pack Tactics", "Spatial Awareness", "Montrals"],
                  abilityBonuses: ["wis": 1, "cha": 1],
                  description: "Sylari are slender beings with bioluminescent skin patterns and heightened Veil perception — rare Tidecallers, often outsiders."),
    ]
}

// MARK: - Character Class Model

struct CBClass: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let hitDie: Int
    let primaryStat: AbilityStat
    let roleDescription: String
    let isForceUser: Bool
    let isTechUser: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case hitDie = "hit_die"
        case primaryStat = "primary_stat"
        case roleDescription = "role_description"
        case isForceUser = "is_force_user"
        case isTechUser = "is_tech_user"
    }

    init(id: String, name: String, hitDie: Int, primaryStat: AbilityStat,
         roleDescription: String, isForceUser: Bool, isTechUser: Bool) {
        self.id = id
        self.name = name
        self.hitDie = hitDie
        self.primaryStat = primaryStat
        self.roleDescription = roleDescription
        self.isForceUser = isForceUser
        self.isTechUser = isTechUser
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        hitDie = try c.decode(Int.self, forKey: .hitDie)
        let statRaw = try c.decode(String.self, forKey: .primaryStat)
        primaryStat = AbilityStat(rawValue: statRaw) ?? .strength
        roleDescription = try c.decode(String.self, forKey: .roleDescription)
        isForceUser = try c.decode(Bool.self, forKey: .isForceUser)
        isTechUser = try c.decode(Bool.self, forKey: .isTechUser)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(hitDie, forKey: .hitDie)
        try c.encode(primaryStat.rawValue, forKey: .primaryStat)
        try c.encode(roleDescription, forKey: .roleDescription)
        try c.encode(isForceUser, forKey: .isForceUser)
        try c.encode(isTechUser, forKey: .isTechUser)
    }

    var classIcon: String {
        switch name.lowercased() {
        case "guardian":  return "shield.fill"
        case "sentinel":  return "eye.fill"
        case "consular":  return "book.closed.fill"
        case "engineer":  return "wrench.and.screwdriver.fill"
        case "fighter":   return "figure.martial.arts"
        case "smuggler":  return "creditcard.fill"
        case "operative": return "theatermasks.fill"
        case "scholar":   return "graduationcap.fill"
        default:          return "person.fill"
        }
    }

    var gradientColors: [Color] {
        switch name.lowercased() {
        case "guardian":  return [.veilGold, .veilGoldSubtle]
        case "sentinel":  return [Color(red: 0.49, green: 0.23, blue: 0.93), Color(red: 0.30, green: 0.11, blue: 0.58)]
        case "consular":  return [.veilGlow, Color(red: 0.02, green: 0.37, blue: 0.27)]
        case "engineer":  return [.veilPurple, Color(red: 0.49, green: 0.18, blue: 0.07)]
        case "fighter":   return [Color(red: 0.92, green: 0.35, blue: 0.0), Color(red: 0.26, green: 0.08, blue: 0.03)]
        case "smuggler":  return [Color(red: 0.79, green: 0.54, blue: 0.02), Color(red: 0.44, green: 0.25, blue: 0.07)]
        case "operative": return [Color(red: 0.60, green: 0.20, blue: 0.50), Color(red: 0.25, green: 0.05, blue: 0.25)]
        case "scholar":   return [Color(red: 0.20, green: 0.60, blue: 0.80), Color(red: 0.05, green: 0.25, blue: 0.45)]
        default:          return [.veilGold, .veilGoldSubtle]
        }
    }

    static let samples: [CBClass] = [
        CBClass(id: "guardian",   name: "Tidecaller", hitDie: 10, primaryStat: .strength,
                roleDescription: "Veil-wielding warriors who protect the Tide. Masters of Veilblade combat.",
                isForceUser: true, isTechUser: false),
        CBClass(id: "sentinel",   name: "Warden",     hitDie: 8,  primaryStat: .dexterity,
                roleDescription: "Agile scouts who blend martial skill with Veil techniques and investigation.",
                isForceUser: true, isTechUser: false),
        CBClass(id: "consular",   name: "Lorekeeper", hitDie: 6,  primaryStat: .wisdom,
                roleDescription: "Diplomatic Veil users who wield powerful Veil powers over brute combat.",
                isForceUser: true, isTechUser: false),
        CBClass(id: "engineer",   name: "Fabricant",  hitDie: 8,  primaryStat: .intelligence,
                roleDescription: "Tech specialists who modify weapons, control machines, and wield tech powers.",
                isForceUser: false, isTechUser: true),
        CBClass(id: "fighter",   name: "Fighter",   hitDie: 10, primaryStat: .strength,
                roleDescription: "Master warriors trained in all forms of combat, unmatched in sustained fighting.",
                isForceUser: false, isTechUser: false),
        CBClass(id: "smuggler",  name: "Smuggler",  hitDie: 8,  primaryStat: .dexterity,
                roleDescription: "Cunning operators who rely on luck, skill, and knowing when to run.",
                isForceUser: false, isTechUser: false),
        CBClass(id: "operative", name: "Operative", hitDie: 8,  primaryStat: .dexterity,
                roleDescription: "Trained spies and assassins who excel at stealth and precision strikes.",
                isForceUser: false, isTechUser: false),
        CBClass(id: "scholar",   name: "Scholar",   hitDie: 6,  primaryStat: .intelligence,
                roleDescription: "Brilliant minds who support allies with expertise, medicine, and tactics.",
                isForceUser: false, isTechUser: true),
    ]
}

// MARK: - Background Model

struct CBBackground: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let skillGrants: [String]
    let featureDescription: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case skillGrants = "skill_grants"
        case featureDescription = "feature_description"
    }

    static let samples: [CBBackground] = [
        CBBackground(id: "outlaw",        name: "Outlaw",
                     skillGrants: ["Deception", "Stealth"],
                     featureDescription: "You can always find a criminal safe house in any settlement."),
        CBBackground(id: "soldier",       name: "Soldier",
                     skillGrants: ["Athletics", "Intimidation"],
                     featureDescription: "Your military rank earns respect. Soldiers in most armies will cooperate."),
        CBBackground(id: "scavenger",     name: "Scavenger",
                     skillGrants: ["Perception", "Survival"],
                     featureDescription: "You find value in discarded tech and can salvage useful parts from wrecks."),
        CBBackground(id: "tidecaller-initiate", name: "Tidecaller Initiate",
                     skillGrants: ["Insight", "History"],
                     featureDescription: "Trained in the Tidecaller Order. Access Tidecaller resources and refuge in sanctuaries."),
        CBBackground(id: "bounty-hunter", name: "Bounty Hunter",
                     skillGrants: ["Perception", "Investigation"],
                     featureDescription: "Contacts in criminal networks. You can get intel on any target for the right price."),
        CBBackground(id: "noble",         name: "Noble",
                     skillGrants: ["Persuasion", "History"],
                     featureDescription: "Born to wealth. You have access to the upper echelons of galactic society."),
        CBBackground(id: "pilot",         name: "Pilot",
                     skillGrants: ["Piloting", "Acrobatics"],
                     featureDescription: "Extensive flight experience. Acquiring a ship or passage is rarely a problem."),
        CBBackground(id: "tech-specialist", name: "Tech Specialist",
                     skillGrants: ["Technology", "Investigation"],
                     featureDescription: "Expert with droids and tech. You can maintain any technological device."),
    ]
}

// MARK: - Power Model

struct CBPower: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let level: Int          // 0 = cantrip / at-will
    let type: String        // "force" or "tech"
    let duration: String
    let description: String
    let cost: String

    var isCantrip: Bool { level == 0 }

    enum CodingKeys: String, CodingKey {
        case id, name, level, type, duration, description, cost
    }

    static let forceSamples: [CBPower] = [
        CBPower(id: "veil-push",    name: "Veil Push",    level: 0, type: "force",
                duration: "Instant",       description: "Push a creature or object with the Veil.", cost: "At-will"),
        CBPower(id: "veil-pull",    name: "Veil Pull",    level: 0, type: "force",
                duration: "Instant",       description: "Pull a nearby object into your hand.", cost: "At-will"),
        CBPower(id: "sense-veil",   name: "Sense Veil",   level: 0, type: "force",
                duration: "Concentration", description: "Sense Veil emanations of nearby living beings.", cost: "At-will"),
        CBPower(id: "veil-bond",    name: "Veil Bond",    level: 1, type: "force",
                duration: "1 hour",        description: "Create a mental link with a willing creature.", cost: "2 FP"),
        CBPower(id: "veil-blind",   name: "Veil Blind",   level: 1, type: "force",
                duration: "1 minute",      description: "Blind a target with surging Veil energy.", cost: "2 FP"),
        CBPower(id: "veil-absorb",  name: "Veil Absorb",  level: 1, type: "force",
                duration: "Instant",       description: "Absorb Veil damage that would harm you.", cost: "2 FP"),
    ]

    static let techSamples: [CBPower] = [
        CBPower(id: "minor-hologram", name: "Minor Hologram", level: 0, type: "tech",
                duration: "1 minute", description: "Create a small holographic image or sound.", cost: "At-will"),
        CBPower(id: "shock",          name: "Shock",          level: 0, type: "tech",
                duration: "Instant",  description: "Deliver a jolt of electricity to a target.", cost: "At-will"),
        CBPower(id: "repair-droid",   name: "Repair Droid",   level: 0, type: "tech",
                duration: "Instant",  description: "Restore 1d6 hit points to a droid or construct.", cost: "At-will"),
        CBPower(id: "overcharge",     name: "Overcharge",     level: 1, type: "tech",
                duration: "Instant",  description: "Supercharge a weapon for extra damage on next attack.", cost: "2 TP"),
        CBPower(id: "decryption",     name: "Decryption",     level: 1, type: "tech",
                duration: "10 min",   description: "Slice through electronic security systems.", cost: "2 TP"),
        CBPower(id: "flash-bang",     name: "Flash Bang",     level: 1, type: "tech",
                duration: "Instant",  description: "Throw a tech grenade that blinds and deafens.", cost: "2 TP"),
    ]
}

// MARK: - Equipment Model

struct CBEquipment: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let type: String        // "weapon", "armor", "gear", "consumable"
    let weight: Double
    let isDefault: Bool
    let description: String
    var isSelected: Bool

    init(id: String, name: String, type: String, weight: Double,
         isDefault: Bool, description: String, isSelected: Bool = true) {
        self.id = id
        self.name = name
        self.type = type
        self.weight = weight
        self.isDefault = isDefault
        self.description = description
        self.isSelected = isSelected
    }

    var typeIcon: String {
        switch type {
        case "weapon":     return "scope"
        case "armor":      return "shield.fill"
        case "gear":       return "backpack.fill"
        case "consumable": return "cross.vial.fill"
        default:           return "cube.fill"
        }
    }

    var encumbranceLabel: String { String(format: "%.1f lb", weight) }

    static func samples(forClass className: String) -> [CBEquipment] {
        var items: [CBEquipment] = [
            CBEquipment(id: "basic-clothes", name: "Basic Clothing",  type: "armor",      weight: 2.0,  isDefault: true,  description: "Standard adventuring outfit."),
            CBEquipment(id: "utility-belt",  name: "Utility Belt",    type: "gear",       weight: 0.5,  isDefault: true,  description: "Holds up to 20 lbs of small items."),
            CBEquipment(id: "medpac",        name: "Medpac",          type: "consumable", weight: 1.0,  isDefault: true,  description: "Restores 2d4+2 hit points."),
            CBEquipment(id: "comlink",       name: "Comlink",         type: "gear",       weight: 0.25, isDefault: false, description: "Short-range communicator, 1-mile range."),
        ]
        switch className.lowercased() {
        case "tidecaller", "fighter", "warden":
            items.append(CBEquipment(id: "veilblade",    name: "Veilblade",           type: "weapon", weight: 1.0,  isDefault: true,  description: "1d8 energy, finesse, versatile (1d10)."))
            items.append(CBEquipment(id: "light-armor",  name: "Light Battle Armor",  type: "armor",  weight: 13.0, isDefault: true,  description: "AC 12 + DEX modifier."))
        case "smuggler", "operative":
            items.append(CBEquipment(id: "blaster-pistol", name: "Blaster Pistol",    type: "weapon", weight: 2.0, isDefault: true,  description: "1d6 energy, range 40/160 ft."))
            items.append(CBEquipment(id: "holdout-blaster", name: "Holdout Blaster",  type: "weapon", weight: 0.5, isDefault: false, description: "1d4 energy, concealable, 30/120 ft."))
        case "fabricant", "scholar":
            items.append(CBEquipment(id: "techblade",    name: "Techblade",           type: "weapon", weight: 2.0, isDefault: true,  description: "1d6 kinetic, finesse."))
            items.append(CBEquipment(id: "tech-kit",     name: "Tech Kit",            type: "gear",   weight: 4.0, isDefault: true,  description: "Required for casting tech powers."))
        case "lorekeeper":
            items.append(CBEquipment(id: "veil-staff",   name: "Veil-imbued Staff",   type: "weapon", weight: 3.0, isDefault: true,  description: "1d6 kinetic, versatile (1d8), focus."))
            items.append(CBEquipment(id: "robes",        name: "Lorekeeper Robes",    type: "armor",  weight: 4.0, isDefault: true,  description: "AC 10 + WIS modifier (Veil Focus)."))
        default:
            items.append(CBEquipment(id: "blaster-pistol", name: "Blaster Pistol",    type: "weapon", weight: 2.0, isDefault: true,  description: "1d6 energy, range 40/160 ft."))
        }
        return items
    }
}

// MARK: - Ability Scores

enum AbilityStat: String, CaseIterable, Codable {
    case strength     = "STR"
    case dexterity    = "DEX"
    case constitution = "CON"
    case intelligence = "INT"
    case wisdom       = "WIS"
    case charisma     = "CHA"

    var fullName: String {
        switch self {
        case .strength:     return "Strength"
        case .dexterity:    return "Dexterity"
        case .constitution: return "Constitution"
        case .intelligence: return "Intelligence"
        case .wisdom:       return "Wisdom"
        case .charisma:     return "Charisma"
        }
    }
}

struct AbilityScores: Equatable {
    var strength:     Int = 8
    var dexterity:    Int = 8
    var constitution: Int = 8
    var intelligence: Int = 8
    var wisdom:       Int = 8
    var charisma:     Int = 8

    // D&D 5E point-buy cost table (base 8, max 15 pre-racial)
    static let pointCost: [Int: Int] = [
        8: 0, 9: 1, 10: 2, 11: 3, 12: 4, 13: 5, 14: 7, 15: 9
    ]
    static let maxPoints = 27

    var pointsSpent: Int {
        [strength, dexterity, constitution, intelligence, wisdom, charisma]
            .compactMap { Self.pointCost[$0] }
            .reduce(0, +)
    }

    var pointsRemaining: Int { Self.maxPoints - pointsSpent }

    func modifier(for score: Int) -> Int { (score - 10) / 2 }

    var strengthMod:     Int { modifier(for: strength) }
    var dexterityMod:    Int { modifier(for: dexterity) }
    var constitutionMod: Int { modifier(for: constitution) }
    var intelligenceMod: Int { modifier(for: intelligence) }
    var wisdomMod:       Int { modifier(for: wisdom) }
    var charismaMod:     Int { modifier(for: charisma) }

    func value(for stat: AbilityStat) -> Int {
        switch stat {
        case .strength:     return strength
        case .dexterity:    return dexterity
        case .constitution: return constitution
        case .intelligence: return intelligence
        case .wisdom:       return wisdom
        case .charisma:     return charisma
        }
    }

    mutating func setValue(_ v: Int, for stat: AbilityStat) {
        switch stat {
        case .strength:     strength     = v
        case .dexterity:    dexterity    = v
        case .constitution: constitution = v
        case .intelligence: intelligence = v
        case .wisdom:       wisdom       = v
        case .charisma:     charisma     = v
        }
    }

    mutating func increase(_ stat: AbilityStat) {
        let current = value(for: stat)
        guard current < 15,
              let nextCost = Self.pointCost[current + 1],
              let curCost  = Self.pointCost[current],
              pointsRemaining >= (nextCost - curCost) else { return }
        setValue(current + 1, for: stat)
    }

    mutating func decrease(_ stat: AbilityStat) {
        let current = value(for: stat)
        guard current > 8 else { return }
        setValue(current - 1, for: stat)
    }
}

// MARK: - Character Draft (in-progress creation)

struct CharacterDraft {
    var species:           CBSpecies?   = nil
    var charClass:         CBClass?     = nil
    var background:        CBBackground? = nil
    var abilityScores:     AbilityScores = AbilityScores()
    var selectedPowers:    [CBPower]    = []
    var selectedEquipment: [CBEquipment] = []
    var name:        String = ""
    var age:         String = ""
    var appearance:  String = ""
    var backstory:   String = ""

    var isReadyToSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && species != nil && charClass != nil && background != nil
    }

    var totalWeight: Double {
        selectedEquipment.filter { $0.isSelected }.reduce(0) { $0 + $1.weight }
    }

    func toPayload() -> [String: Any] {
        [
            "name":         name,
            "species":      species?.name ?? "",
            "class":        charClass?.name ?? "",
            "background":   background?.name ?? "",
            "strength":     abilityScores.strength,
            "dexterity":    abilityScores.dexterity,
            "constitution": abilityScores.constitution,
            "intelligence": abilityScores.intelligence,
            "wisdom":       abilityScores.wisdom,
            "charisma":     abilityScores.charisma,
            "powers":       selectedPowers.map { $0.id },
            "equipment":    selectedEquipment.filter { $0.isSelected }.map { $0.id },
            "age":          age,
            "appearance":   appearance,
            "backstory":    backstory,
        ]
    }
}
