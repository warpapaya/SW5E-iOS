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
struct Campaign: Identifiable, Codable {
    let id: String
    var title: String
    var currentLocation: String   // derived from worldState.currentLocation on decode
    var difficulty: DifficultyLevel
    var gmStyle: GMStyle
    var gameState: GameState

    struct GameState: Codable {
        var active: Bool = true
        var combatState: CombatState = CombatState()
        var history: [GameHistoryEntry] = []
        var suggestedChoices: [SuggestedChoice] = []
        var activeCharacter: Character?
    }

    init(id: String, title: String, currentLocation: String,
         difficulty: DifficultyLevel = .normal, gmStyle: GMStyle = .cinematic,
         gameState: GameState) {
        self.id = id
        self.title = title
        self.currentLocation = currentLocation
        self.difficulty = difficulty
        self.gmStyle = gmStyle
        self.gameState = gameState
    }

    // MARK: Encodable
    enum StoredKeys: String, CodingKey {
        case id, title, currentLocation, difficulty, gmStyle, gameState
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: StoredKeys.self)
        try c.encode(id,              forKey: .id)
        try c.encode(title,           forKey: .title)
        try c.encode(currentLocation, forKey: .currentLocation)
        try c.encode(difficulty,      forKey: .difficulty)
        try c.encode(gmStyle,         forKey: .gmStyle)
        try c.encode(gameState,       forKey: .gameState)
    }

    // MARK: Decodable — maps backend shape
    enum BackendKeys: String, CodingKey {
        case id, title, currentScene, combatState, history, worldState, difficulty, gmStyle
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: BackendKeys.self)
        id    = try c.decode(String.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? "Campaign"

        difficulty = try c.decodeIfPresent(DifficultyLevel.self, forKey: .difficulty) ?? .normal
        gmStyle    = try c.decodeIfPresent(GMStyle.self,         forKey: .gmStyle)    ?? .cinematic

        if let ws = try? c.decodeIfPresent(WorldState.self, forKey: .worldState) {
            currentLocation = ws.currentLocation
        } else {
            currentLocation = "Unknown"
        }

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

// MARK: - Backend Shape Helpers (decode-only)

struct BackendNPC: Codable {
    var name: String
    var disposition: String?
    var description: String?
}

struct BackendScene: Codable {
    var description: String
    var location: String?
    var choices: [String]
    var npcs: [BackendNPC]?
}

struct BackendHistoryEntry: Codable {
    var type: String        // "narration" | "action" | "combat"
    var text: String
    var timestamp: String?
}

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

// MARK: - Action Request (legacy — kept for compatibility)

struct ActionRequest: Codable {
    let campaignId: String
    let action: String
}

// MARK: - Campaign Settings Enums

/// Difficulty levels for campaigns (matches backend values)
enum DifficultyLevel: String, Codable, CaseIterable {
    case story   = "story"
    case normal  = "normal"
    case heroic  = "heroic"

    var displayName: String {
        switch self {
        case .story:  return "Story"
        case .normal: return "Normal"
        case .heroic: return "Heroic"
        }
    }

    var icon: String {
        switch self {
        case .story:  return "book.fill"
        case .normal: return "shield.fill"
        case .heroic: return "flame.fill"
        }
    }
}

/// GM narrative style (matches backend values)
enum GMStyle: String, Codable, CaseIterable {
    case cinematic = "cinematic"
    case gritty    = "gritty"
    case comedic   = "comedic"

    var displayName: String {
        switch self {
        case .cinematic: return "Cinematic"
        case .gritty:    return "Gritty"
        case .comedic:   return "Comedic"
        }
    }

    var icon: String {
        switch self {
        case .cinematic: return "film.fill"
        case .gritty:    return "bolt.fill"
        case .comedic:   return "face.smiling.fill"
        }
    }
}

// MARK: - AI Status (from /api/ai/status)

/// Backend AI availability response
struct AIStatus: Codable {
    let available: Bool
    let backends: AIBackends?
    let message: String?

    struct AIBackends: Codable {
        let ollama: Bool?
        let lmStudio: Bool?
    }

    static let offline = AIStatus(available: false, backends: nil, message: "Offline")
}

// MARK: - Travel Result (from /api/game/travel)

struct TravelResult: Codable {
    let success: Bool
    let route: RouteInfo?
    let encounter: String?
    let arrivalScene: BackendScene?
    let narration: String?
}

struct RouteInfo: Codable {
    let fromPlanet: String?
    let toPlanet: String?
    let waypoints: [String]?
    let totalDistance: Double?
    let numJumps: Int?
    let estimatedTravelTimeHours: Double?
}

// MARK: - Demo Campaign Data

extension Campaign {
    static func demo(id: String = "demo-campaign-1") -> Campaign {
        let character = Character.demos.first
        return Campaign(
            id: id,
            title: "Shadows of the Void",
            currentLocation: "Solara Prime, Level 1313",
            difficulty: .normal,
            gmStyle: .cinematic,
            gameState: Campaign.GameState(
                active: true,
                combatState: CombatState(),
                history: [
                    GameHistoryEntry(
                        type: .gmNarration,
                        content: "You stand in the dimly lit corridors of Solara Prime's Level 1313. The air is thick with the scent of industrial oil and distant crime. Neon signs flicker in alien scripts. A hooded figure emerges from the shadows ahead — robes dark, posture coiled. The Veil whispers danger."
                    ),
                    GameHistoryEntry(
                        type: .gmNarration,
                        content: "The figure pauses ten meters away. \"I've been waiting for you,\" a low voice says. A red blade snaps to life, painting the corridor in blood-crimson light. The confrontation has begun."
                    ),
                ],
                suggestedChoices: [
                    SuggestedChoice(text: "Draw my Veilblade and stand ready", emoji: "⚔️"),
                    SuggestedChoice(text: "Use Veil Sense to read their intent",  emoji: "✨"),
                    SuggestedChoice(text: "Try to negotiate or stall for time",    emoji: "💬"),
                    SuggestedChoice(text: "Draw my blaster and take cover",        emoji: "🔫"),
                ],
                activeCharacter: character
            )
        )
    }
}

// MARK: - Server Configuration

struct ServerConfig: Codable {
    var url: String
    let timeoutSeconds: Int

    static let `default` = ServerConfig(url: "https://sw5e-api.petieclark.com", timeoutSeconds: 30)
}
