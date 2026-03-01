import Foundation
import SwiftUI

/// View model for the GamePlay main screen.
/// Handles campaign loading, action submission, combat routing, AI status polling,
/// XP display, undo, session summary, and difficulty/gmStyle settings.
@MainActor
class GamePlayViewModel: ObservableObject {

    // MARK: - Dependencies

    private let api = APIService.shared
    private let campaignId: String
    private let soundManager = SoundManager.shared

    // MARK: - Published State

    @Published var campaign: Campaign?
    @Published var isLoadingCampaign = false
    @Published var isProcessingAction = false
    @Published var isUndoing = false
    @Published var isFetchingSummary = false
    @Published var errorMessage: String?

    @Published var selectedChoiceId: UUID? = nil

    // AI status — polled on load and every 60s
    @Published var isAIOnline: Bool = false
    @Published var aiStatusMessage: String = "Checking AI status…"

    // XP Toast
    @Published var xpToastAmount: Int = 0
    @Published var showXPToast: Bool = false

    // Session summary sheet
    @Published var sessionSummary: String? = nil
    @Published var showSessionSummaryBanner = false
    @Published var sessionSummaryText = ""

    // Veilborn tracking (for Veilblade hum)
    @Published var isActiveForceUser = false

    // Campaign settings editing
    @Published var selectedDifficulty: DifficultyLevel = .normal
    @Published var selectedGMStyle: GMStyle = .cinematic

    // MARK: - Private

    private var aiPollTask: Task<Void, Never>?

    // MARK: - Computed

    var currentLocation: String { campaign?.currentLocation ?? "Unknown Location" }
    var canSendAction: Bool { !isProcessingAction && campaign != nil }

    // MARK: - Init / Deinit

    init(campaignId: String) {
        self.campaignId = campaignId
    }

    deinit {
        aiPollTask?.cancel()
    }

    // MARK: - Campaign Loading

    func loadCampaign() async {
        isLoadingCampaign = true
        errorMessage = nil

        do {
            let campaignData = try await api.fetchCampaign(id: campaignId)
            self.campaign = campaignData
            selectedDifficulty = campaignData.difficulty
            selectedGMStyle    = campaignData.gmStyle
            checkForceUserStatus(character: campaignData.gameState.activeCharacter)

            if !campaignData.gameState.history.isEmpty {
                showSessionSummaryBanner = true
                sessionSummaryText = "Previous session loaded. Continue where you left off?"
            }
        } catch {
            // Offline — load demo campaign so UI remains usable
            let demo = Campaign.demo(id: campaignId)
            self.campaign = demo
            checkForceUserStatus(character: demo.gameState.activeCharacter)
        }

        isLoadingCampaign = false
        startAIStatusPolling()
    }

    // MARK: - AI Status Polling

    private func startAIStatusPolling() {
        aiPollTask?.cancel()
        aiPollTask = Task {
            while !Task.isCancelled {
                await refreshAIStatus()
                try? await Task.sleep(nanoseconds: 60_000_000_000) // 60s
            }
        }
    }

    func refreshAIStatus() async {
        let status = await api.checkAIStatus()
        isAIOnline = status.available
        aiStatusMessage = status.message ?? (status.available ? "AI online" : "AI offline")
    }

    // MARK: - Action Submission

    /// Submits a player action. Routes to combat endpoint when combat is active.
    func submitAction(actionText: String, selectedChoiceId: UUID? = nil) async {
        guard canSendAction else { return }

        isProcessingAction = true
        self.selectedChoiceId = nil

        // Optimistically append player entry
        let playerEntry = GameHistoryEntry(type: .playerAction, content: actionText)
        campaign?.gameState.history.append(playerEntry)

        do {
            if campaign?.gameState.combatState.active == true {
                // Route to combat action endpoint
                let result = try await api.submitCombatAction(
                    campaignId: campaignId,
                    action: actionText
                )
                if let narration = result.narration {
                    campaign?.gameState.history.append(
                        GameHistoryEntry(type: .combatResult, content: narration)
                    )
                }
                if let newState = result.combatState {
                    campaign?.gameState.combatState = newState
                }
                soundManager.playBlasterShot()
            } else {
                // Normal narrative action
                let result = try await api.submitAction(campaignId: campaignId, action: actionText)

                if let narration = result.narration {
                    let entryType: GameHistoryEntry.EntryType =
                        (result.combatState?.active == true) ? .combatResult : .gmNarration
                    campaign?.gameState.history.append(
                        GameHistoryEntry(type: entryType, content: narration)
                    )
                }
                if let newCombatState = result.combatState {
                    campaign?.gameState.combatState = newCombatState
                }
                let choices = result.resolvedChoices
                if !choices.isEmpty {
                    campaign?.gameState.suggestedChoices = choices
                }

                // XP Award toast
                if let xp = result.xpAwarded, xp > 0 {
                    showXPAward(xp)
                }
            }
        } catch {
            // Offline / demo fallback
            let demoReplies = [
                "The Veil stirs as you act. The outcome ripples through the galaxy. *[AI Game Master offline — connect your server to continue]*",
                "Your action echoes through the corridors of fate. *[Demo mode — wire up your Echoveil backend for full AI narration]*",
                "An interesting choice. The galaxy holds its breath... *[Server offline]*",
            ]
            let count = campaign?.gameState.history.count ?? 0
            campaign?.gameState.history.append(
                GameHistoryEntry(type: .gmNarration, content: demoReplies[count % demoReplies.count])
            )
        }

        isProcessingAction = false
    }

    // MARK: - XP Toast

    private func showXPAward(_ amount: Int) {
        xpToastAmount = amount
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showXPToast = true
        }
        soundManager.playXPChime()
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5s
            withAnimation(.easeOut(duration: 0.4)) {
                showXPToast = false
            }
        }
    }

    // MARK: - Undo

    func undoLastAction() async {
        guard !isUndoing else { return }
        isUndoing = true
        do {
            let updated = try await api.undoLastAction(campaignId: campaignId)
            self.campaign = updated
            selectedDifficulty = updated.difficulty
            selectedGMStyle    = updated.gmStyle
        } catch {
            errorMessage = "Undo failed: \(error.localizedDescription)"
        }
        isUndoing = false
    }

    // MARK: - Session Summary

    func fetchSessionSummary() async {
        guard !isFetchingSummary else { return }
        isFetchingSummary = true
        do {
            let response = try await api.getSessionSummary(campaignId: campaignId)
            if let text = response.summary, !text.isEmpty {
                sessionSummary = text
                // Also append to history
                campaign?.gameState.history.append(
                    GameHistoryEntry(type: .sessionSummary, content: text)
                )
            } else {
                sessionSummary = response.message ?? "No summary available yet."
            }
        } catch {
            sessionSummary = "Could not load session summary."
        }
        isFetchingSummary = false
    }

    // MARK: - Campaign Settings

    func applySettings(difficulty: DifficultyLevel, gmStyle: GMStyle) async {
        do {
            let result = try await api.updateCampaignSettings(
                campaignId: campaignId,
                difficulty: difficulty,
                gmStyle: gmStyle
            )
            if let d = result.difficulty { selectedDifficulty = d }
            if let g = result.gmStyle    { selectedGMStyle    = g }
        } catch {
            errorMessage = "Settings update failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Session Banner

    func dismissSessionSummary() {
        showSessionSummaryBanner = false
    }

    // MARK: - Combat Toggle

    func toggleCombatOverlay() {
        campaign?.gameState.combatState.active.toggle()
    }

    // MARK: - Veilborn / Sound

    func checkForceUserStatus(character: Character?) {
        let wasActive = isActiveForceUser
        isActiveForceUser = character?.isForceUser ?? false
        if isActiveForceUser != wasActive {
            isActiveForceUser ? soundManager.startVeilbladeHum() : soundManager.stopVeilbladeHum()
        }
    }

    func playBlasterSound() { soundManager.playBlasterShot() }
    func playDiceRollSound() { soundManager.playDiceRoll() }
    func playXPChimeSound()  { soundManager.playXPChime() }
}

// MARK: - APIClient (thin shim for existing GamePlayView call-sites)

struct APIClient {
    var baseURL: String { APIService.shared.serverURL }

    func fetch<T: Decodable>(_ type: T.Type, endpoint: String) async throws -> (T, Int) {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.badURL(baseURL + endpoint)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        let decoded = try JSONDecoder().decode(type, from: data)
        return (decoded, http.statusCode)
    }

    func post<T: Decodable, B: Encodable>(_ type: T.Type, endpoint: String, body: B) async throws -> (T, Int) {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.badURL(baseURL + endpoint)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        let decoded = try JSONDecoder().decode(type, from: data)
        return (decoded, http.statusCode)
    }
}

// MARK: - Preview Provider
#Preview("GamePlay ViewModel") {
    CampaignListView()
}
