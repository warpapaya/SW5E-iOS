import Foundation
import SwiftUI

// MARK: - SW5E Character Model

/// Star Wars 5th Edition character data model
struct Character: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var name: String
    var species: String
    var charClass: String  // Guardian, Sentinel, Consular, Engineer, Fighter, etc.
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
        charClass: "Guardian",
        level: 1,
        experiencePoints: 0,
        currentHP: 10,
        maxHP: 10,
        ac: 12,
        forcePoints: 0,
        lastModified: Date()
    )
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case species
        case charClass = "class"
        case level
        case experiencePoints = "experience_points"
        case currentHP = "current_hp"
        case maxHP = "max_hp"
        case ac
        case forcePoints = "force_points"
        case lastModified = "last_modified"
    }
}

// MARK: - Character Class Colors

/// Gradient colors for each character class in the SW5E system
enum CharacterClassColor: String, CaseIterable {
    case guardian = "Guardian"      // Blue - Force users, defenders
    case sentinel = "Sentinel"       // Purple - Scouts, investigators
    case consular = "Consular"       // Teal - Diplomats, scholars
    case engineer = "Engineer"       // Green - Tech specialists
    case fighter = "Fighter"         // Orange - Martial combatants
    case smuggler = "Smuggler"       // Yellow - Rogues, operators
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var gradientColors: (Color, Color) {
        switch self {
        case .guardian:
            return (.hologramBlue, .holoBlueSubtle)  // Blue gradient
        case .sentinel:
            return (.lightText, .hologramBlue)       // Purple gradient
        case .consular:
            return (.saberGreen, .spaceCard)         // Teal gradient
        case .engineer:
            return (.techOrange, .siithRed)          // Green-orange gradient
        case .fighter:
            return (.lightText, .mutedText)          // Orange/gray gradient
        case .smuggler:
            return (.hologramBlue, .spaceCard)       // Yellow-blue gradient
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

// MARK: - Force User Detection

// MARK: - Demo Data (offline / first-run fallback)

extension Character {
    static let demos: [Character] = [
        Character(
            id: "demo-1", name: "Kael Voss", species: "Miraluka", charClass: "Guardian",
            level: 7, experiencePoints: 23_000, currentHP: 45, maxHP: 68,
            ac: 16, forcePoints: 12, lastModified: Date().addingTimeInterval(-3_600)
        ),
        Character(
            id: "demo-2", name: "Zara Teth", species: "Twi'lek", charClass: "Sentinel",
            level: 3, experiencePoints: 2_100, currentHP: 22, maxHP: 28,
            ac: 14, forcePoints: 6, lastModified: Date().addingTimeInterval(-86_400)
        ),
        Character(
            id: "demo-3", name: "Brom Skalos", species: "Zabrak", charClass: "Engineer",
            level: 5, experiencePoints: 14_000, currentHP: 38, maxHP: 42,
            ac: 17, forcePoints: 0, lastModified: Date().addingTimeInterval(-7_200)
        ),
        Character(
            id: "demo-4", name: "Lyss Orann", species: "Human", charClass: "Consular",
            level: 4, experiencePoints: 5_500, currentHP: 30, maxHP: 32,
            ac: 13, forcePoints: 20, lastModified: Date().addingTimeInterval(-172_800)
        ),
    ]
}

extension Character {
    /// Check if character is a force user (Jedi, Sith, etc.)
    var isForceUser: Bool {
        // Guardian class often has force powers
        let guardianHasForce = charClass.contains("Guardian") && forcePoints > 0
        
        // Explicit Jedi/Sith/Acolyte classes
        let explicitForceClasses = ["Jedi", "Sith", "Dark Jedi", "Force Acolyte", "Jedi Knight", "Jedi Master"]
        let hasExplicitForceClass = explicitForceClasses.contains { charClass.contains($0) }
        
        // Sentinel can be force-sensitive (investigators, diplomats with powers)
        let sentinelHasForce = charClass.contains("Sentinel") && forcePoints > 0
        
        return guardianHasForce || explicitForceClasses.contains(charClass) || sentinelHasForce
    }
    
    /// Initiative bonus for combat (includes force sensitivity bonus)
    var initiativeBonus: Int {
        // Base dexterity-based bonus
        let baseDexMod = (charClass == "Rogue" || charClass == "Smuggler") ? 4 : 2
        
        // Force users get +1 bonus to initiative (enhanced reflexes)
        return isForceUser ? baseDexMod + 1 : baseDexMod
    }
}
