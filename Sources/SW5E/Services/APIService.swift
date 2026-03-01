import Foundation
import UIKit

// MARK: - API Service for Echoveil Backend

/// Central HTTP client for the Echoveil backend at https://sw5e-api.petieclark.com
/// All public methods are async-safe and non-throwing where possible (AI status).
class APIService: ObservableObject {
    static let shared = APIService()

    /// Persisted in UserDefaults via @AppStorage in SettingsView; mutated on save.
    @Published var serverURL: String {
        didSet { UserDefaults.standard.set(serverURL, forKey: "serverURL") }
    }
    @Published var isConnected: Bool = false

    /// Stable per-device identifier used to scope characters and campaigns.
    /// Generated once on first launch and stored in UserDefaults.
    static var deviceId: String = {
        let key = "echoveil_device_id"
        if let saved = UserDefaults.standard.string(forKey: key) { return saved }
        // Prefer identifierForVendor; fall back to a random UUID
        let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(id, forKey: key)
        return id
    }()

    private init() {
        let saved = UserDefaults.standard.string(forKey: "serverURL") ?? ""
        serverURL = saved.isEmpty ? "https://sw5e-api.petieclark.com" : saved
    }

    // MARK: - Health Check

    func checkConnection() async -> Bool {
        guard let url = URL(string: "\(serverURL)/health") else { return false }
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            let ok = (response as? HTTPURLResponse).map { (200...299).contains($0.statusCode) } ?? false
            await MainActor.run { isConnected = ok }
            return ok
        } catch {
            await MainActor.run { isConnected = false }
            return false
        }
    }

    // MARK: - AI Endpoints

    /// GET /api/ai/status → AIStatus (never throws; returns offline on error)
    func checkAIStatus() async -> AIStatus {
        guard let url = URL(string: "\(serverURL)/api/ai/status") else {
            return AIStatus.offline
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return AIStatus.offline
            }
            return try JSONDecoder().decode(AIStatus.self, from: data)
        } catch {
            return AIStatus.offline
        }
    }

    /// POST /api/ai/backstory → backstory String
    func generateBackstory(name: String, species: String, charClass: String, background: String) async throws -> String {
        let url = try requireURL("/api/ai/backstory")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "name": name, "species": species, "class": charClass, "background": background
        ])
        let (data, resp) = try await URLSession.shared.data(for: req)
        try validateHTTP(resp)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let backstory = json["backstory"] as? String else {
            throw APIError.decodingError("backstory field missing")
        }
        return backstory
    }

    // MARK: - Campaign Endpoints

    /// GET /api/game/campaign/:id
    func fetchCampaign(id: String) async throws -> Campaign {
        var req = URLRequest(url: try requireURL("/api/game/campaign/\(id)"))
        req.timeoutInterval = 15
        return try await decode(Campaign.self, from: req)
    }

    /// GET /api/game/campaigns?characterId= (or bare)
    func fetchCampaignSummaries(characterId: String? = nil) async throws -> [CampaignSummary] {
        var path = "/api/game/campaigns"
        if let cid = characterId { path += "?characterId=\(cid)" }
        var req = URLRequest(url: try requireURL(path))
        req.timeoutInterval = 15
        return try await decode([CampaignSummary].self, from: req)
    }

    /// POST /api/game/start
    func startCampaign(
        characterId: String,
        templateId: String? = nil,
        difficulty: DifficultyLevel? = nil,
        gmStyle: GMStyle? = nil
    ) async throws -> CampaignStartResult {
        var body: [String: Any] = ["characterId": characterId]
        if let t = templateId  { body["templateId"] = t }
        if let d = difficulty  { body["difficulty"]  = d.rawValue }
        if let g = gmStyle     { body["gmStyle"]     = g.rawValue }
        return try await post("/api/game/start", body: body, decode: CampaignStartResult.self)
    }

    /// POST /api/game/action
    func submitAction(campaignId: String, action: String) async throws -> ActionResult {
        let body: [String: Any] = ["campaignId": campaignId, "action": action]
        return try await post("/api/game/action", body: body, decode: ActionResult.self)
    }

    /// DELETE /api/game/campaign/:id/last-action
    func undoLastAction(campaignId: String) async throws -> Campaign {
        let url = try requireURL("/api/game/campaign/\(campaignId)/last-action")
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        let (data, resp) = try await URLSession.shared.data(for: req)
        try validateHTTP(resp)
        let wrapper = try JSONDecoder().decode(UndoResponse.self, from: data)
        return wrapper.campaign
    }

    /// PUT /api/game/campaign/:id/settings
    func updateCampaignSettings(
        campaignId: String,
        difficulty: DifficultyLevel? = nil,
        gmStyle: GMStyle? = nil
    ) async throws -> CampaignSettingsResponse {
        var body: [String: Any] = [:]
        if let d = difficulty { body["difficulty"] = d.rawValue }
        if let g = gmStyle    { body["gmStyle"]    = g.rawValue }
        let url = try requireURL("/api/game/campaign/\(campaignId)/settings")
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await decode(CampaignSettingsResponse.self, from: req)
    }

    /// GET /api/game/campaign/:id/summary
    func getSessionSummary(campaignId: String) async throws -> SessionSummaryResponse {
        let req = URLRequest(url: try requireURL("/api/game/campaign/\(campaignId)/summary"))
        return try await decode(SessionSummaryResponse.self, from: req)
    }

    /// POST /api/game/save
    func saveCampaign(campaignId: String) async throws {
        let body: [String: Any] = ["campaignId": campaignId]
        let _: SaveResponse = try await post("/api/game/save", body: body, decode: SaveResponse.self)
    }

    // MARK: - Combat Endpoints

    /// POST /api/game/combat/start
    func startCombat(campaignId: String, enemies: [[String: Any]] = []) async throws -> CombatState {
        let body: [String: Any] = ["campaignId": campaignId, "enemies": enemies]
        let wrapper: CombatStartResponse = try await post("/api/game/combat/start", body: body, decode: CombatStartResponse.self)
        return wrapper.combatState ?? CombatState()
    }

    /// POST /api/game/combat/action
    func submitCombatAction(
        campaignId: String,
        action: String,
        target: String? = nil,
        powerId: String? = nil,
        itemId: String? = nil
    ) async throws -> CombatActionResult {
        var body: [String: Any] = ["campaignId": campaignId, "action": action]
        if let t = target   { body["target"]  = t }
        if let p = powerId  { body["powerId"] = p }
        if let i = itemId   { body["itemId"]  = i }
        return try await post("/api/game/combat/action", body: body, decode: CombatActionResult.self)
    }

    // MARK: - Travel

    /// POST /api/game/travel
    func travelTo(campaignId: String, fromPlanet: String, toPlanet: String) async throws -> TravelResult {
        let body: [String: Any] = [
            "campaignId": campaignId,
            "fromPlanet": fromPlanet,
            "toPlanet": toPlanet
        ]
        return try await post("/api/game/travel", body: body, decode: TravelResult.self)
    }

    // MARK: - Character Endpoints

    func fetchCharacters() async throws -> [Character] {
        return try await decode([Character].self, from: URLRequest(url: try requireURL("/api/characters")))
    }

    func fetchCharacter(id: String) async throws -> Character {
        var req = URLRequest(url: try requireURL("/api/characters/\(id)"))
        req.timeoutInterval = 15
        return try await decode(Character.self, from: req)
    }

    func createCharacter(_ character: Character) async throws -> Character {
        let url = try requireURL("/api/characters")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(character)
        return try await decode(Character.self, from: req)
    }

    func updateCharacter(_ character: Character) async throws -> Character {
        let url = try requireURL("/api/characters/\(character.id)")
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(character)
        return try await decode(Character.self, from: req)
    }

    func deleteCharacter(id: String) async throws {
        let url = try requireURL("/api/characters/\(id)")
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        let (_, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode == 404 { return }
        try validateHTTP(resp)
    }

    func deleteCampaign(id: String) async throws {
        let url = try requireURL("/api/game/campaign/\(id)")
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        let (_, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode == 404 { return }
        try validateHTTP(resp)
    }

    // MARK: - Generic Helpers

    private func requireURL(_ path: String) throws -> URL {
        guard let url = URL(string: serverURL + path) else {
            throw APIError.badURL(serverURL + path)
        }
        return url
    }

    private func validateHTTP(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(statusCode: http.statusCode)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from request: URLRequest) async throws -> T {
        var req = request
        req.setValue(APIService.deviceId, forHTTPHeaderField: "X-Device-Id")
        let (data, response) = try await URLSession.shared.data(for: req)
        try validateHTTP(response)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }

    private func post<T: Decodable>(
        _ path: String,
        body: [String: Any],
        decode type: T.Type
    ) async throws -> T {
        var req = URLRequest(url: try requireURL(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(APIService.deviceId, forHTTPHeaderField: "X-Device-Id")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await self.decode(type, from: req)
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case badURL(String)
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .badURL(let url):         return "Invalid URL: \(url)"
        case .invalidResponse:         return "Invalid server response"
        case .httpError(let code):     return "HTTP \(code)"
        case .decodingError(let msg):  return "Decode error: \(msg)"
        }
    }
}

// Keep legacy name for existing callers
typealias APIServiceError = APIError

// MARK: - Response Wrapper Types

/// Wraps DELETE /api/game/campaign/:id/last-action response
struct UndoResponse: Codable {
    let success: Bool
    let campaign: Campaign
}

/// Wraps POST /api/game/save
struct SaveResponse: Codable {
    let success: Bool
}

/// Wraps POST /api/game/combat/start
struct CombatStartResponse: Codable {
    let combatState: CombatState?
    let message: String?
}

// MARK: - Shared Result Types (used by APIService + ViewModels)

/// POST /api/game/start result
struct CampaignStartResult: Codable {
    let campaignId: String
    let scene: BackendScene?
}

/// POST /api/game/action result
struct ActionResult: Codable {
    let scene: BackendScene?
    let combatState: CombatState?
    let characterUpdates: [CharacterUpdate]?
    let xpAwarded: Int?
    let message: String?
    let suggestedChoices: [String]?  // backend may return top-level suggestedChoices

    var narration: String? { scene?.description }
    var resolvedChoices: [SuggestedChoice] {
        // Prefer top-level suggestedChoices, fall back to scene.choices
        let raw = suggestedChoices ?? scene?.choices ?? []
        return raw.map { SuggestedChoice(text: $0) }
    }
}

/// POST /api/game/combat/action result
struct CombatActionResult: Codable {
    let combatState: CombatState?
    let narration: String?
    let characterUpdates: [CharacterUpdate]?
}

/// Character HP/XP updates embedded in action responses
struct CharacterUpdate: Codable {
    let id: String?
    let currentHp: Int?
    let maxHp: Int?
    let forcePoints: Int?
    let xp: Int?
}

/// GET /api/game/campaign/:id/summary
struct SessionSummaryResponse: Codable {
    let summary: String?
    let message: String?
    let historyCount: Int?
    let usedEntries: Int?
}

/// PUT /api/game/campaign/:id/settings response
struct CampaignSettingsResponse: Codable {
    let success: Bool
    let difficulty: DifficultyLevel?
    let gmStyle: GMStyle?
    let message: String?
}
