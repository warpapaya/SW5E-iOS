import Foundation
import SwiftUI

/// View model for the GamePlay main screen.
/// Handles campaign loading, action submission, combat state management, and UI state.
@MainActor
class GamePlayViewModel: ObservableObject {
    // MARK: - Dependencies
    
    private let apiClient: APIClient
    private let campaignId: String
    private let soundManager = SoundManager.shared
    
    /// Track if current character is a force user (for lightsaber hum)
    @Published var isActiveForceUser = false
    
    // MARK: - Published State
    
    @Published var campaign: Campaign?
    @Published var isLoadingCampaign = false
    @Published var isProcessingAction = false
    @Published var errorMessage: String?
    
    @Published var selectedChoiceId: UUID? = nil
    @Published var showSessionSummaryBanner = false
    @Published var sessionSummaryText = ""
    
    // MARK: - Computed Properties
    
    var currentLocation: String {
        campaign?.currentLocation ?? "Unknown Location"
    }
    
    var isAIOnline: Bool {
        // In production, check AI backend status endpoint
        true // Placeholder
    }
    
    var canSendAction: Bool {
        !isProcessingAction && errorMessage == nil
    }
    
    // MARK: - Initialization
    
    init(apiClient: APIClient = APIClient(), campaignId: String) {
        self.apiClient = apiClient
        self.campaignId = campaignId
    }
    
    // MARK: - Public Methods
    
    /// Load the campaign data from API, fall back to demo mode if server is offline
    func loadCampaign() async {
        isLoadingCampaign = true
        errorMessage = nil

        do {
            var req = URLRequest(url: URL(string: apiClient.baseURL + "/api/game/campaign/\(campaignId)")!)
            req.timeoutInterval = 15 // Increased for HTTPS production
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            let campaignData = try JSONDecoder().decode(Campaign.self, from: data)

            if !campaignData.gameState.history.isEmpty {
                showSessionSummaryBanner = true
                sessionSummaryText = "Previous session ended. Continue where you left off?"
            }
            self.campaign = campaignData
            checkForceUserStatus(character: campaignData.gameState.activeCharacter)

        } catch {
            // Offline / server unreachable — load demo campaign so UI is usable
            self.campaign = Campaign.demo(id: campaignId)
            checkForceUserStatus(character: self.campaign?.gameState.activeCharacter)
        }

        isLoadingCampaign = false
    }
    
    /// Submit a player action to the game engine, with offline demo fallback
    func submitAction(actionText: String, selectedChoiceId: UUID? = nil) async throws {
        guard canSendAction else { return }

        isProcessingAction = true

        // Record the player's action immediately
        let playerEntry = GameHistoryEntry(type: .playerAction, content: actionText)
        campaign?.gameState.history.append(playerEntry)
        self.selectedChoiceId = nil

        do {
            let request = ActionRequest(campaignId: campaignId, action: actionText)
            let (response, _) = try await apiClient.post(ActionResponse.self, endpoint: "/api/game/action", body: request)

            if !response.success {
                throw NSError(domain: "GameAction", code: 1, userInfo: [NSLocalizedDescriptionKey: "Server rejected action"])
            }

            if let narration = response.narration {
                let entryType = historyEntryType(forNarration: narration) ?? .gmNarration
                campaign?.gameState.history.append(GameHistoryEntry(type: entryType, content: narration))
            }
            if let newCombatState = response.combatState {
                campaign?.gameState.combatState = newCombatState
            }
            if let newChoices = response.suggestedChoices {
                campaign?.gameState.suggestedChoices = newChoices
            }

        } catch {
            // Offline / demo mode: generate a placeholder GM response
            let demoReplies = [
                "The Force stirs as you act. The outcome ripples through the galaxy in ways you cannot yet foresee. *[AI Game Master offline — connect your server to continue the story]*",
                "Your action echoes through the corridors of fate. The shadows shift in response. *[Demo mode — wire up your SW5E backend for full AI narration]*",
                "An interesting choice. The galaxy holds its breath... *[Server offline — start your backend at localhost:3001]*",
            ]
            let historyCount = campaign?.gameState.history.count ?? 0
            let reply = demoReplies[historyCount % demoReplies.count]
            campaign?.gameState.history.append(GameHistoryEntry(type: .gmNarration, content: reply))
        }

        isProcessingAction = false
    }
    
    /// Dismiss the session summary banner
    func dismissSessionSummary() {
        showSessionSummaryBanner = false
    }
    
    /// Toggle combat overlay visibility (manual override)
    func toggleCombatOverlay() {
        campaign?.gameState.combatState.active.toggle()
    }
    
    // MARK: - Sound Integration
    
    /// Check if current character is a force user and update sound accordingly
    func checkForceUserStatus(character: Character?) {
        let wasActive = isActiveForceUser
        
        // Use the computed property from Character model
        isActiveForceUser = character?.isForceUser ?? false
        
        if isActiveForceUser != wasActive {
            if isActiveForceUser {
                soundManager.startLightsaberHum()
            } else {
                soundManager.stopLightsaberHum()
            }
        }
    }
    
    /// Play blaster shot (combat action)
    func playBlasterSound() {
        soundManager.playBlasterShot()
    }
    
    /// Play dice roll (dice action)
    func playDiceRollSound() {
        soundManager.playDiceRoll()
    }
    
    /// Play XP chime (level up)
    func playXPChimeSound() {
        soundManager.playXPChime()
    }
    
    // MARK: - Private Helpers
    
    private func historyEntryType(forNarration narration: String) -> GameHistoryEntry.EntryType? {
        if narration.contains("combat") || narration.contains("attack") || narration.contains("damage") {
            return .combatResult
        }
        return .gmNarration // Default to GM narration for story text
    }
}

/// APIClient - Simple HTTP client for API calls
struct APIClient {
    var baseURL: String { APIService.shared.serverURL }
    
    func fetch<T: Decodable>(_ type: T.Type, endpoint: String) async throws -> (T, Int) {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NSError(domain: "InvalidURL", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: -1, userInfo: nil)
        }
        
        let decoded = try JSONDecoder().decode(T.self, from: data)
        return (decoded, httpResponse.statusCode)
    }
    
    func post<T: Decodable, B: Encodable>(_ type: T.Type, endpoint: String, body: B) async throws -> (T, Int) {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NSError(domain: "InvalidURL", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw error
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: -1, userInfo: nil)
        }
        
        let decoded = try JSONDecoder().decode(T.self, from: data)
        return (decoded, httpResponse.statusCode)
    }
}

// MARK: - Preview Provider
#Preview("GamePlay ViewModel") {
    CampaignListView()
}
