import Foundation
import SwiftUI

// MARK: - Campaign Start / List View Model

@MainActor
class CampaignStartViewModel: ObservableObject {

    // MARK: - Published State

    @Published var savedCampaigns: [CampaignSummary] = []
    @Published var characters: [Character] = []

    @Published var isLoadingCampaigns = false
    @Published var isLoadingCharacters = false
    @Published var isStarting = false
    @Published var errorMessage: String?

    // AI status
    @Published var aiAvailable: Bool = false
    @Published var aiBackend: String?

    // Navigation trigger: set to non-nil to push GamePlayView
    @Published var launchedCampaignId: String?

    // MARK: - Private

    private var baseURL: String { APIService.shared.serverURL }

    init() {}

    // MARK: - Load

    func loadAll() async {
        async let campaigns: Void = loadCampaigns()
        async let chars: Void     = loadCharacters()
        async let ai: Void        = checkAIStatus()
        _ = await (campaigns, chars, ai)
    }

    func loadCampaigns() async {
        isLoadingCampaigns = true
        defer { isLoadingCampaigns = false }
        do {
            let url = URL(string: "\(baseURL)/api/game/campaigns")!
            var req = URLRequest(url: url)
            req.timeoutInterval = 15 // Increased timeout for HTTPS production load
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            savedCampaigns = try decoder.decode([CampaignSummary].self, from: data)
        } catch {
            // Offline / no server — fall back to demo campaigns
            savedCampaigns = CampaignSummary.demos
        }
    }

    func loadCharacters() async {
        isLoadingCharacters = true
        defer { isLoadingCharacters = false }
        do {
            let url = URL(string: "\(baseURL)/api/characters")!
            var req = URLRequest(url: url)
            req.timeoutInterval = 5
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            characters = try decoder.decode([Character].self, from: data)
        } catch {
            characters = Character.demos
        }
    }

    func checkAIStatus() async {
        let status = await APIService.shared.checkAIStatus()
        aiAvailable = status.available
        aiBackend   = status.message
    }

    // MARK: - Character Sync

    /// Ensures a character exists on the server by posting it (upsert).
    /// Returns success for 200/201/409; only throws network errors.
    private func ensureCharacterSynced(_ character: Character) async {
        let url = URL(string: "\(baseURL)/api/characters")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 10
        req.httpBody = try? JSONEncoder().encode(character)

        do {
            let (_, response) = try await URLSession.shared.data(for: req)
            // 200 (already exists), 201 (created), or 409 (conflict) are all acceptable — don't throw
            guard let http = response as? HTTPURLResponse else { return }
            if !(200...201).contains(http.statusCode) && http.statusCode != 409 {
                // Network error already thrown by data() call; ignore other HTTP errors
            }
        } catch {
            // Best-effort sync — don't block campaign start
            print("Character sync failed: \(error.localizedDescription)")
        }
    }

    /// Finds a character in the local array by ID.
    private func findCharacter(by id: String) -> Character? {
        characters.first { $0.id == id }
    }

    // MARK: - Start New Campaign

    /// POST /api/game/start — shows animated loading, navigates on success.
    /// Before starting, attempts to sync the character to the server (upsert).
    func startCampaign(templateId: String?, characterId: String) async {
        guard !isStarting else { return }
        isStarting = true
        errorMessage = nil

        // Best-effort character sync before campaign start
        if let character = findCharacter(by: characterId) {
            await ensureCharacterSynced(character)
        }

        let body = CampaignStartRequest(
            templateId: templateId,
            characterId: characterId,
            title: nil
        )

        do {
            let url = URL(string: "\(baseURL)/api/game/start")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let started = try JSONDecoder().decode(CampaignStartResponse.self, from: data)
            launchedCampaignId = started.campaignId

        } catch {
            errorMessage = "Failed to start campaign: \(error.localizedDescription)"
        }

        isStarting = false
    }

    // MARK: - Resume Campaign

    func resumeCampaign(_ summary: CampaignSummary) {
        launchedCampaignId = summary.id
    }
}
