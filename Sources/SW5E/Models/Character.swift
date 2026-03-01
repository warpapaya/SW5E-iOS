import Foundation
import SwiftUI

// MARK: - Echoveil Character Model

/// Echoveil character data model
struct Character: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var name: String
    var species: String
    var charClass: String  // Tidecaller, Warden, Lorekeeper, Fabricant, Fighter, etc.
    var level: Int
    var experiencePoints: Int
    var currentHP: Int
    var maxHP: Int
    var ac: Int  // Armor Class
    var forcePoints: Int
    var lastModified: Date
    
    // Computed properties
    var hpPercentage: Double {
        guard maxHP > 0 else { return 1.0 }
        return Double(currentHP) / Double(maxHP)
    }
    
    var isNew: Bool {
        return level == 1 && experiencePoints < 300
    }
    
    static let `default`: Self = Character(
        id: "",
        name: "New Character",
        species: "Human",
        charClass: "Tidecaller",
        level: 1,
        experiencePoints: 0,
        currentHP: 10,
        maxHP: 10,
        ac: 12,
        forcePoints: 0,
        lastModified: Date()
    )
    
    // Explicit memberwise init (required because custom init(from:) suppresses synthesis)
    init(id: String, name: String, species: String, charClass: String,
         level: Int, experiencePoints: Int, currentHP: Int, maxHP: Int,
         ac: Int, forcePoints: Int, lastModified: Date) {
        self.id = id; self.name = name; self.species = species; self.charClass = charClass
        self.level = level; self.experiencePoints = experiencePoints
        self.currentHP = currentHP; self.maxHP = maxHP; self.ac = ac
        self.forcePoints = forcePoints; self.lastModified = lastModified
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case species
        case charClass    = "class"
        case level
        case experiencePoints = "xp"          // backend: "xp"
        case currentHP    = "currentHp"       // backend: "currentHp"
        case maxHP        = "maxHp"           // backend: "maxHp"
        case ac           = "armorClass"      // backend: "armorClass"
        case forcePoints                      // not in backend — defaults to 0
        case lastModified = "updatedAt"       // backend: "updatedAt"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decode(String.self, forKey: .id)
        name             = try c.decode(String.self, forKey: .name)
        species          = try c.decodeIfPresent(String.self, forKey: .species)   ?? "Unknown"
        charClass        = try c.decodeIfPresent(String.self, forKey: .charClass) ?? "Tidecaller"
        level            = try c.decodeIfPresent(Int.self,    forKey: .level)     ?? 1
        experiencePoints = try c.decodeIfPresent(Int.self,    forKey: .experiencePoints) ?? 0
        currentHP        = try c.decodeIfPresent(Int.self,    forKey: .currentHP) ?? 10
        maxHP            = try c.decodeIfPresent(Int.self,    forKey: .maxHP)     ?? 10
        ac               = try c.decodeIfPresent(Int.self,    forKey: .ac)        ?? 10
        forcePoints      = try c.decodeIfPresent(Int.self,    forKey: .forcePoints) ?? 0
        let dateStr      = try c.decodeIfPresent(String.self, forKey: .lastModified) ?? ""
        let fmt          = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        lastModified     = fmt.date(from: dateStr) ?? Date()
    }
}

// MARK: - Character Class Colors

/// Gradient colors for each character class in the Echoveil system
enum CharacterClassColor: String, CaseIterable {
    case guardian = "Tidecaller"    // Blue - Veil users, defenders
    case sentinel = "Warden"        // Purple - Scouts, investigators
    case consular = "Lorekeeper"    // Teal - Diplomats, scholars
    case engineer = "Fabricant"     // Green - Tech specialists
    case fighter = "Fighter"         // Orange - Martial combatants
    case smuggler = "Smuggler"       // Yellow - Rogues, operators
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var gradientColors: (Color, Color) {
        switch self {
        case .guardian:
            return (.veilGold, .veilGoldSubtle)  // Blue gradient
        case .sentinel:
            return (.lightText, .veilGold)       // Purple gradient
        case .consular:
            return (.veilGlow, .spaceCard)         // Teal gradient
        case .engineer:
            return (.veilPurple, .voidRed)          // Green-orange gradient
        case .fighter:
            return (.lightText, .mutedText)          // Orange/gray gradient
        case .smuggler:
            return (.veilGold, .spaceCard)       // Yellow-blue gradient
        }
    }
    
    var icon: String {
        switch self {
        case .guardian: return "shield.fill"
        case .sentinel: return "magnifyingglass"
        case .consular: return "book.closed"
        case .engineer: return "wrench.and.screwdriver"
        case .fighter: return "sword"
        case .smuggler: return "exclamationmark.shield.fill"
        }
    }
}

// MARK: - Veilborn Detection

// MARK: - Demo Data (offline / first-run fallback)

extension Character {
    static let demos: [Character] = [
        Character(
            id: "demo-1", name: "Kael Voss", species: "Arion", charClass: "Tidecaller",
            level: 7, experiencePoints: 23_000, currentHP: 45, maxHP: 68,
            ac: 16, forcePoints: 12, lastModified: Date().addingTimeInterval(-3_600)
        ),
        Character(
            id: "demo-2", name: "Zara Teth", species: "Sylari", charClass: "Warden",
            level: 3, experiencePoints: 2_100, currentHP: 22, maxHP: 28,
            ac: 14, forcePoints: 6, lastModified: Date().addingTimeInterval(-86_400)
        ),
        Character(
            id: "demo-3", name: "Brom Skalos", species: "Zabrak", charClass: "Fabricant",
            level: 5, experiencePoints: 14_000, currentHP: 38, maxHP: 42,
            ac: 17, forcePoints: 0, lastModified: Date().addingTimeInterval(-7_200)
        ),
        Character(
            id: "demo-4", name: "Lyss Orann", species: "Arion", charClass: "Lorekeeper",
            level: 4, experiencePoints: 5_500, currentHP: 30, maxHP: 32,
            ac: 13, forcePoints: 20, lastModified: Date().addingTimeInterval(-172_800)
        ),
    ]
}

extension Character {
    /// Check if character is a Veil user (Tidecaller, Voidshaper, etc.)
    var isForceUser: Bool {
        // Tidecaller class often has Veil powers
        let tidecallerHasVeil = charClass.contains("Tidecaller") && forcePoints > 0
        
        // Explicit Veilborn classes
        let explicitVeilClasses = ["Tidecaller", "Voidshaper", "Lorekeeper", "Warden", "Veil Acolyte"]
        let hasExplicitVeilClass = explicitVeilClasses.contains { charClass.contains($0) }
        
        // Warden can be Veilborn (investigators, diplomats with powers)
        let wardenHasVeil = charClass.contains("Warden") && forcePoints > 0
        
        return tidecallerHasVeil || hasExplicitVeilClass || wardenHasVeil
    }
    
    /// Initiative bonus for combat (includes force sensitivity bonus)
    var initiativeBonus: Int {
        // Base dexterity-based bonus
        let baseDexMod = (charClass == "Rogue" || charClass == "Smuggler") ? 4 : 2
        
        // Veilborn users get +1 bonus to initiative (enhanced reflexes)
        return isForceUser ? baseDexMod + 1 : baseDexMod
    }
}
