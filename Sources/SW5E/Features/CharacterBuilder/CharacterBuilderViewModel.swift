import SwiftUI

// MARK: - Builder Steps Enum

enum BuilderStep: Int, CaseIterable {
    case species    = 0
    case charClass  = 1
    case background = 2
    case ability    = 3
    case powers     = 4
    case equipment  = 5
    case details    = 6
    case review     = 7

    var title: String {
        switch self {
        case .species:    return "Species"
        case .charClass:  return "Class"
        case .background: return "Background"
        case .ability:    return "Ability Scores"
        case .powers:     return "Powers"
        case .equipment:  return "Equipment"
        case .details:    return "Details"
        case .review:     return "Review"
        }
    }

    var icon: String {
        switch self {
        case .species:    return "figure.stand"
        case .charClass:  return "shield.fill"
        case .background: return "book.fill"
        case .ability:    return "chart.bar.fill"
        case .powers:     return "sparkles"
        case .equipment:  return "backpack.fill"
        case .details:    return "pencil"
        case .review:     return "checkmark.seal.fill"
        }
    }
}

// MARK: - Character Builder ViewModel

@MainActor
final class CharacterBuilderViewModel: ObservableObject {

    // MARK: Progress
    @Published var currentStep: BuilderStep = .species
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isSaving: Bool = false
    @Published var savedCharacterID: String? = nil

    // MARK: Draft
    @Published var draft: CharacterDraft = CharacterDraft()

    // MARK: Data
    @Published var availableSpecies:     [CBSpecies]     = []
    @Published var availableClasses:     [CBClass]       = []
    @Published var availableBackgrounds: [CBBackground]  = []
    @Published var availablePowers:      [CBPower]       = []
    @Published var availableEquipment:   [CBEquipment]   = []

    // MARK: UI State
    @Published var isGeneratingBackstory: Bool = false

    private let api = APIService.shared

    // MARK: - Step Navigation

    /// Steps that require Force/Tech classes are only shown when relevant
    var visibleSteps: [BuilderStep] {
        if draft.charClass?.isForceUser == true || draft.charClass?.isTechUser == true {
            return BuilderStep.allCases
        } else {
            return BuilderStep.allCases.filter { $0 != .powers }
        }
    }

    var totalVisibleSteps: Int { visibleSteps.count }

    var currentVisibleIndex: Int {
        visibleSteps.firstIndex(of: currentStep) ?? 0
    }

    var canGoBack: Bool {
        currentVisibleIndex > 0
    }

    var canProceed: Bool {
        switch currentStep {
        case .species:    return draft.species != nil
        case .charClass:  return draft.charClass != nil
        case .background: return draft.background != nil
        case .ability:    return draft.abilityScores.pointsRemaining >= 0
        case .powers:     return true      // Optional step
        case .equipment:  return true      // Pre-filled, optional changes
        case .details:    return !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .review:     return draft.isReadyToSave
        }
    }

    func goNext() {
        let idx = currentVisibleIndex
        guard idx < visibleSteps.count - 1 else { return }
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStep = visibleSteps[idx + 1]
        }
        Task { await loadDataForStep(visibleSteps[idx + 1]) }
    }

    func goBack() {
        let idx = currentVisibleIndex
        guard idx > 0 else { return }
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStep = visibleSteps[idx - 1]
        }
    }

    // MARK: - Selection Helpers

    func select(species: CBSpecies) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        draft.species = species
    }

    func select(charClass: CBClass) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        draft.charClass = charClass
        // Reset powers when class changes
        draft.selectedPowers = []
        // Pre-fill equipment for this class
        draft.selectedEquipment = CBEquipment.samples(forClass: charClass.name)
    }

    func select(background: CBBackground) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        draft.background = background
    }

    func togglePower(_ power: CBPower) {
        UISelectionFeedbackGenerator().selectionChanged()
        if draft.selectedPowers.contains(power) {
            draft.selectedPowers.removeAll { $0.id == power.id }
        } else {
            draft.selectedPowers.append(power)
        }
    }

    func isPowerSelected(_ power: CBPower) -> Bool {
        draft.selectedPowers.contains(power)
    }

    func toggleEquipment(at index: Int) {
        guard index < draft.selectedEquipment.count else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        draft.selectedEquipment[index].isSelected.toggle()
    }

    // MARK: - Data Loading

    func loadInitialData() async {
        await loadSpecies()
        await loadClasses()
        await loadBackgrounds()
    }

    private func loadDataForStep(_ step: BuilderStep) async {
        switch step {
        case .species:    await loadSpecies()
        case .charClass:  await loadClasses()
        case .background: await loadBackgrounds()
        case .powers:     await loadPowers()
        case .equipment:  await loadEquipment()
        default: break
        }
    }

    private func loadSpecies() async {
        guard availableSpecies.isEmpty else { return }
        isLoading = true
        do {
            let url = URL(string: "\(api.serverURL)/api/data/species")!
            let (data, _) = try await URLSession.shared.data(from: url)
            availableSpecies = try JSONDecoder().decode([CBSpecies].self, from: data)
        } catch {
            availableSpecies = CBSpecies.samples
        }
        isLoading = false
    }

    private func loadClasses() async {
        guard availableClasses.isEmpty else { return }
        isLoading = true
        do {
            let url = URL(string: "\(api.serverURL)/api/data/classes")!
            let (data, _) = try await URLSession.shared.data(from: url)
            availableClasses = try JSONDecoder().decode([CBClass].self, from: data)
        } catch {
            availableClasses = CBClass.samples
        }
        isLoading = false
    }

    private func loadBackgrounds() async {
        guard availableBackgrounds.isEmpty else { return }
        isLoading = true
        do {
            let url = URL(string: "\(api.serverURL)/api/data/backgrounds")!
            let (data, _) = try await URLSession.shared.data(from: url)
            availableBackgrounds = try JSONDecoder().decode([CBBackground].self, from: data)
        } catch {
            availableBackgrounds = CBBackground.samples
        }
        isLoading = false
    }

    private func loadPowers() async {
        let classId = draft.charClass?.id ?? ""
        isLoading = true
        do {
            let url = URL(string: "\(api.serverURL)/api/data/powers/force")!
            let (data, _) = try await URLSession.shared.data(from: url)
            availablePowers = try JSONDecoder().decode([CBPower].self, from: data)
        } catch {
            if draft.charClass?.isForceUser == true {
                availablePowers = CBPower.forceSamples
            } else {
                availablePowers = CBPower.techSamples
            }
        }
        isLoading = false
    }

    private func loadEquipment() async {
        let className = draft.charClass?.name ?? ""
        // Equipment is pre-seeded in select(charClass:); just ensure it's filled
        if draft.selectedEquipment.isEmpty {
            draft.selectedEquipment = CBEquipment.samples(forClass: className)
        }
    }

    // MARK: - AI Backstory Generation

    func generateBackstory() async {
        isGeneratingBackstory = true
        defer { isGeneratingBackstory = false }

        let payload: [String: Any] = [
            "name":       draft.name,
            "species":    draft.species?.name ?? "",
            "class":      draft.charClass?.name ?? "",
            "background": draft.background?.name ?? "",
        ]
        do {
            let url = URL(string: "\(api.serverURL)/api/ai/backstory")!
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let text = json["backstory"] as? String {
                draft.backstory = text
            }
        } catch {
            draft.backstory = "A wanderer of the galaxy, \(draft.name) comes from humble beginnings, shaped by hardship and destiny."
        }
    }

    // MARK: - Save Character

    func createCharacter() async -> Bool {
        guard draft.isReadyToSave else { return false }
        isSaving = true
        defer { isSaving = false }

        let payload = draft.toPayload()
        do {
            let url = URL(string: "\(api.serverURL)/api/characters")!
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let id = json["id"] as? String {
                savedCharacterID = id
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                return true
            }
        } catch {
            errorMessage = "Failed to create character: \(error.localizedDescription)"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        return false
    }
}
