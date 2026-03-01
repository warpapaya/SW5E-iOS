import Foundation

// MARK: - Campaign Summary (list view model from /api/game/campaigns)

/// Lightweight campaign summary returned by the campaign list API.
/// Full `Campaign` model is only loaded when entering a campaign.
struct CampaignSummary: Identifiable, Codable {
    let id: String
    var title: String
    var characterName: String
    var characterClass: String      // not in API response — default ""
    var lastPlayedAt: Date          // maps from "updatedAt"
    var currentLocation: String     // not in API response — default "Unknown"
    var isActive: Bool              // always true

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case characterName   // backend returns camelCase
        case characterClass  // not in response — custom decode below
        case lastPlayedAt    = "updatedAt"
        case currentLocation // not in response — custom decode below
        case isActive        // not in response — custom decode below
    }

    init(id: String, title: String, characterName: String, characterClass: String = "",
         lastPlayedAt: Date, currentLocation: String = "Unknown", isActive: Bool = true) {
        self.id = id
        self.title = title
        self.characterName = characterName
        self.characterClass = characterClass
        self.lastPlayedAt = lastPlayedAt
        self.currentLocation = currentLocation
        self.isActive = isActive
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        characterName = try container.decodeIfPresent(String.self, forKey: .characterName) ?? "Unknown"
        characterClass = try container.decodeIfPresent(String.self, forKey: .characterClass) ?? ""
        
        let dateStr = try container.decodeIfPresent(String.self, forKey: .lastPlayedAt) ?? ""
        let isoFormatter = ISO8601DateFormatter()
        lastPlayedAt = isoFormatter.date(from: dateStr) ?? Date()
        
        currentLocation = try container.decodeIfPresent(String.self, forKey: .currentLocation) ?? "Unknown"
        isActive = true
    }
}

// MARK: - Campaign Template

/// Static template cards for the "New Campaign" template picker.
struct CampaignTemplate: Identifiable {
    let id: String
    let title: String
    let era: String
    let description: String
    let difficulty: Difficulty
    let icon: String                     // SF Symbol name
    let accentColor: TemplateColor

    enum Difficulty: String, CaseIterable {
        case easy      = "Easy"
        case moderate  = "Moderate"
        case hard      = "Hard"
        case brutal    = "Brutal"

        var stars: Int {
            switch self {
            case .easy:     return 1
            case .moderate: return 2
            case .hard:     return 3
            case .brutal:   return 4
            }
        }
    }

    enum TemplateColor {
        case blue, purple, red, gold
    }

    // MARK: - Built-in Templates

    static let driftwayJob = CampaignTemplate(
        id: "driftway-job",
        title: "The Driftway Job",
        era: "Sovereignty Era",
        description: "A mercenary heist in the criminal underworld of the Merchant Drift — nothing on the Driftway is ever as simple as it sounds.",
        difficulty: .moderate,
        icon: "shippingbox.fill",
        accentColor: .gold
    )

    static let tidecallerAwakening = CampaignTemplate(
        id: "tidecaller-awakening",
        title: "Tidecaller Awakening",
        era: "Sovereignty Era",
        description: "Discover the Veil and forge your identity at a hidden Tidecaller academy on Ashenveil. But the Void whispers, and not every Initiate survives their trials.",
        difficulty: .hard,
        icon: "sparkles",
        accentColor: .blue
    )

    static let fracturedCell = CampaignTemplate(
        id: "fractured-cell",
        title: "Fractured Cell",
        era: "Sovereignty Era",
        description: "Espionage and guerrilla warfare deep inside Sovereignty territory — fighting for a galaxy that does not yet know it can be free.",
        difficulty: .hard,
        icon: "shield.lefthalf.filled",
        accentColor: .red
    )

    static let sandbox = CampaignTemplate(
        id: "sandbox",
        title: "Freeform",
        era: "Your Choice",
        description: "No rails, no script. The AI Game Master builds a galaxy around your choices. Define your era, your faction, your story.",
        difficulty: .easy,
        icon: "wand.and.sparkles",
        accentColor: .purple
    )

    static let all: [CampaignTemplate] = [.driftwayJob, .tidecallerAwakening, .fracturedCell, .sandbox]
}

// MARK: - Demo Data

extension CampaignSummary {
    static let demos: [CampaignSummary] = [
        CampaignSummary(
            id: "demo-campaign-1",
            title: "Shadows of the Void",
            characterName: "Kael Voss",
            characterClass: "Tidecaller",
            lastPlayedAt: Date().addingTimeInterval(-21_600),
            currentLocation: "Solara Prime, Level 1313",
            isActive: true
        ),
    ]
}

// MARK: - Campaign Start Request / Response

struct CampaignStartRequest: Codable {
    let templateId: String?
    let characterId: String
    let title: String?
    let characterData: Character?   // Inline character so server can auto-create if not synced yet
}

struct CampaignStartResponse: Codable {
    let campaignId: String
    let scene: BackendScene?

    var openingScene: String { scene?.description ?? "" }
}

// MARK: - AI Status

struct AIStatusResponse: Codable {
    let available: Bool
    let backend: String?
    let model: String?
}
