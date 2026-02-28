import Foundation

// MARK: - Game Models

/// Represents a single narrative/action entry in the game history
struct GameHistoryEntry: Identifiable, Equatable, Codable {
    let id: UUID
    enum EntryType: String, Codable { case gmNarration, playerAction, combatResult, sessionSummary }
    let type: EntryType
    let content: String
    let timestamp: Date

    init(type: EntryType, content: String) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.timestamp = Date()
    }
}

/// Current scene's suggested choices for player to tap
struct SuggestedChoice: Identifiable, Codable {
    let id: UUID
    let text: String
    let emoji: String?

    init(text: String, emoji: String? = nil) {
        self.id = UUID()
        self.text = text
        self.emoji = emoji
    }
}

/// Combat state tracking - plain struct, no @Published, Codable for API
struct CombatState: Equatable, Codable {
    var active: Bool = false
    var currentTurnIndex: Int = 0
    var participants: [Combatant] = []

    enum CodingKeys: String, CodingKey {
        case active
        case currentTurnIndex = "currentTurn"
        case participants     = "initiative"
    }

    init(active: Bool = false, currentTurnIndex: Int = 0, participants: [Combatant] = []) {
        self.active = active
        self.currentTurnIndex = currentTurnIndex
        self.participants = participants
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        active           = try c.decodeIfPresent(Bool.self,        forKey: .active)           ?? false
        currentTurnIndex = try c.decodeIfPresent(Int.self,         forKey: .currentTurnIndex) ?? 0
        participants     = try c.decodeIfPresent([Combatant].self, forKey: .participants)     ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(active,           forKey: .active)
        try c.encode(currentTurnIndex, forKey: .currentTurnIndex)
        try c.encode(participants,     forKey: .participants)
    }
}

/// Single combat participant
struct Combatant: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var hp: Int
    var maxHp: Int
    var ac: Int
    var initiative: Int?
    var conditions: [String] = []

    init(name: String, hp: Int, maxHp: Int, ac: Int, initiative: Int? = nil, conditions: [String] = []) {
        self.id = UUID()
        self.name = name
        self.hp = hp
        self.maxHp = maxHp
        self.ac = ac
        self.initiative = initiative
        self.conditions = conditions
    }
}

// MARK: - Campaign

/// Campaign data received from the API.
/// Uses a custom decoder to map the backend shape; encoding uses simple stored-property keys.
struct Campaign: Identifiable, Codable {
    let id: String
    var title: String
    var currentLocation: String   // derived from worldState.currentLocation on decode
    var gameState: GameState

    // MARK: Inner types

    struct GameState: Codable {
        var active: Bool = true
        var combatState: CombatState = CombatState()
        var history: [GameHistoryEntry] = []
        var suggestedChoices: [SuggestedChoice] = []
        var activeCharacter: Character?
    }

    // MARK: Memberwise init (used by demo data and in-app construction)

    init(id: String, title: String, currentLocation: String, gameState: GameState) {
        self.id = id
        self.title = title
        self.currentLocation = currentLocation
        self.gameState = gameState
    }

    // MARK: Encodable — encode stored properties directly

    enum StoredKeys: String, CodingKey {
        case id, title, currentLocation, gameState
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: StoredKeys.self)
        try c.encode(id,              forKey: .id)
        try c.encode(title,           forKey: .title)
        try c.encode(currentLocation, forKey: .currentLocation)
        try c.encode(gameState,       forKey: .gameState)
    }

    // MARK: Decodable — maps backend shape

    enum BackendKeys: String, CodingKey {
        case id, title, currentScene, combatState, history, worldState
    }

    init(from decoder: Decoder) throws {
        // Try backend shape first
        let c = try decoder.container(keyedBy: BackendKeys.self)
        id    = try c.decode(String.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? "Campaign"

        // Extract currentLocation from worldState
        if let ws = try? c.decodeIfPresent(WorldState.self, forKey: .worldState) {
            currentLocation = ws.currentLocation
        } else {
            currentLocation = "Unknown"
        }

        // Build GameState from backend fields
        let history     = try c.decodeIfPresent([BackendHistoryEntry].self, forKey: .history)     ?? []
        let combatState = try c.decodeIfPresent(CombatState.self,           forKey: .combatState) ?? CombatState()
        let scene       = try c.decodeIfPresent(BackendScene.self,          forKey: .currentScene)

        let converted = history.compactMap { GameHistoryEntry(from: $0) }
        let choices   = scene?.choices.map { SuggestedChoice(text: $0) } ?? []

        gameState = GameState(
            active: true,
            combatState: combatState,
            history: converted,
            suggestedChoices: choices,
            activeCharacter: nil
        )
    }
}

// MARK: - Backend Shape Helpers (decode-only, not used for encoding)

/// Backend scene shape — used when decoding campaign and action responses
struct BackendScene: Codable {
    var description: String
    var location: String?
    var choices: [String]
    var npcs: [String]?
}

/// Backend history entry
struct BackendHistoryEntry: Codable {
    var type: String        // "narration" | "action" | "combat"
    var text: String
    var timestamp: String?
}

/// WorldState — only the fields we need
struct WorldState: Codable {
    var currentLocation: String
}

extension GameHistoryEntry {
    init?(from backend: BackendHistoryEntry) {
        switch backend.type {
        case "narration": self.init(type: .gmNarration,  content: backend.text)
        case "action":    self.init(type: .playerAction, content: backend.text)
        case "combat":    self.init(type: .combatResult, content: backend.text)
        default:          self.init(type: .gmNarration,  content: backend.text)
        }
    }
}

// MARK: - Action Request / Response

/// POST /api/game/action  body
struct ActionRequest: Codable {
    let campaignId: String
    let action: String

    // Backend expects camelCase keys — no snake_case needed
    enum CodingKeys: String, CodingKey {
        case campaignId
        case action
    }
}

/// POST /api/game/action  response
struct ActionResponse: Codable {
    let scene: BackendScene?
    let combatState: CombatState?
    let xpAwarded: Int?

    var narration: String?         { scene?.description }
    var suggestedChoices: [SuggestedChoice]? { scene?.choices.map { SuggestedChoice(text: $0) } }
    var success: Bool              { scene != nil }
}

// MARK: - Demo Campaign Data

extension Campaign {
    /// Demo campaign shown when server is offline.
    static func demo(id: String = "demo-campaign-1") -> Campaign {
        let character = Character.demos.first
        return Campaign(
            id: id,
            title: "Shadows of the Sith",
            currentLocation: "Coruscant, Level 1313",
            gameState: Campaign.GameState(
                active: true,
                combatState: CombatState(),
                history: [
                    GameHistoryEntry(
                        type: .gmNarration,
                        content: "You stand in the dimly lit corridors of Coruscant's Level 1313. The air is thick with the scent of industrial oil and distant crime. Neon signs flicker in alien scripts. A hooded figure emerges from the shadows ahead — robes dark, posture coiled. The Force whispers danger."
                    ),
                    GameHistoryEntry(
                        type: .gmNarration,
                        content: "The figure pauses ten meters away. \"I've been waiting for you,\" a low voice says. A red blade snaps to life, painting the corridor in blood-crimson light. The confrontation has begun."
                    ),
                ],
                suggestedChoices: [
                    SuggestedChoice(text: "Ignite my lightsaber and stand ready", emoji: "⚔️"),
                    SuggestedChoice(text: "Use Force Sense to read their intent",  emoji: "✨"),
                    SuggestedChoice(text: "Try to negotiate or stall for time",    emoji: "💬"),
                    SuggestedChoice(text: "Draw my blaster and take cover",        emoji: "🔫"),
                ],
                activeCharacter: character
            )
        )
    }
}

// MARK: - Server configuration for settings
struct ServerConfig: Codable {
    var url: String
    let timeoutSeconds: Int

    enum CodingKeys: String, CodingKey {
        case url
        case timeoutSeconds = "timeout_seconds"
    }

    static let `default`: Self = Self(url: "https://sw5e-api.petieclark.com", timeoutSeconds: 30)
}
