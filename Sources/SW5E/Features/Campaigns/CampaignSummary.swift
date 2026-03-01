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

    static let outerRimJob = CampaignTemplate(
        id: "outer-rim-job",
        title: "Outer Rim Job",
        era: "Sovereignty Era",
        description: "A shady cargo run turns deadly when you discover what's really in those crates. Smugglers, bounty hunters, and desperate choices await beyond the Core.",
        difficulty: .moderate,
        icon: "shippingbox.fill",
        accentColor: .gold
    )

    static let jediAcademy = CampaignTemplate(
        id: "jedi-academy",
        title: "Tidecaller Academy",
        era: "New Republic",
        description: "Warden Aelith has taken you as an Initiate. But the Void whispers, and not every Tidecaller survives their trials. How will you face your destiny?",
        difficulty: .hard,
        icon: "sparkles",
        accentColor: .blue
    )

    static let rebelCell = CampaignTemplate(
        id: "rebel-cell",
        title: "Fractured Coalition Cell",
        era: "Galactic Civil War",
        description: "Deep in Sovereignty space, your small cell of Fractured fighters fights for survival. Every mission could be your last—and the Sovereignty is always watching.",
        difficulty: .hard,
        icon: "shield.lefthalf.filled",
        accentColor: .red
    )

    static let sandbox = CampaignTemplate(
        id: "sandbox",
        title: "Sandbox",
        era: "Your Choice",
        description: "No rails, no script. The AI Game Master creates a galaxy around your decisions. Define your era, your faction, your story.",
        difficulty: .easy,
        icon: "wand.and.sparkles",
        accentColor: .purple
    )

    static let all: [CampaignTemplate] = [.outerRimJob, .jediAcademy, .rebelCell, .sandbox]
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
    // Backend expects camelCase — no CodingKeys needed
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
