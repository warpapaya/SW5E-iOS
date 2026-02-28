import SwiftUI

// MARK: - Combat API Models

/// POST /api/game/combat/action request body
private struct CombatActionRequest: Encodable {
    let campaignId: String
    let action: String
    let targetId: String?

    enum CodingKeys: String, CodingKey {
        case campaignId = "campaign_id"
        case action
        case targetId  = "target_id"
    }
}

/// Response from POST /api/game/combat/action
private struct CombatActionResponse: Decodable {
    let success: Bool
    let narration: String?
    let d20Roll: Int?
    let modifier: Int?
    let total: Int?
    let hit: Bool?
    let damageRoll: Int?
    let damageType: String?
    let updatedParticipants: [CombatantPayload]?
    let currentTurnIndex: Int?
    let combatEnded: Bool?
    let victory: Bool?
    let xpAwarded: Int?

    enum CodingKeys: String, CodingKey {
        case success, narration, hit, modifier, total
        case d20Roll              = "d20_roll"
        case damageRoll           = "damage_roll"
        case damageType           = "damage_type"
        case updatedParticipants  = "updated_participants"
        case currentTurnIndex     = "current_turn_index"
        case combatEnded          = "combat_ended"
        case victory
        case xpAwarded            = "xp_awarded"
    }
}

/// Participant data from server (richer than local Combatant stub)
private struct CombatantPayload: Decodable, Identifiable {
    let id: String
    let name: String
    let hp: Int
    let maxHp: Int
    let ac: Int
    let initiative: Int
    let conditions: [String]
    let isPlayer: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, hp, ac, initiative, conditions
        case maxHp    = "max_hp"
        case isPlayer = "is_player"
    }
}

// MARK: - Combat ViewModel

@MainActor
final class CombatViewModel: ObservableObject {

    // MARK: Combat roster (seeded from CombatState, updated from API)
    @Published var participants: [CombatParticipant] = []
    @Published var currentTurnIndex: Int = 0

    // MARK: UI state
    @Published var pendingAction: CombatActionType? = nil
    @Published var showTargetSheet = false
    @Published var isSubmitting = false

    // MARK: Attack resolution
    @Published var attackResult: AttackResult? = nil
    @Published var showDiceOverlay = false
    @Published var showDamageOverlay = false

    // MARK: Enemy narration
    @Published var enemyNarration: String? = nil

    // MARK: Combat end
    @Published var combatEnded = false
    @Published var victory = false
    @Published var xpAwarded = 0

    // MARK: Log (last 20 entries, view shows last 5)
    @Published var combatLog: [String] = []

    private let campaignId: String
    private let apiClient: APIClient
    var onCombatEnded: () -> Void = {}

    // MARK: - Nested Types

    struct CombatParticipant: Identifiable {
        var id: UUID
        var name: String
        var hp: Int
        var maxHp: Int
        var ac: Int
        var initiative: Int
        var conditions: [String]
        var isPlayer: Bool
    }

    struct AttackResult {
        let hit: Bool
        let d20Roll: Int
        let modifier: Int
        let total: Int
        let damage: Int?
        let damageType: String?
    }

    enum CombatActionType: String, CaseIterable {
        case attack      = "attack"
        case usePower    = "use_power"
        case disengage   = "disengage"
        case dash        = "dash"
        case dodge       = "dodge"
        case help        = "help"
        case endTurn     = "end_turn"

        var label: String {
            switch self {
            case .attack:    return "Attack"
            case .usePower:  return "Use Power"
            case .disengage: return "Disengage"
            case .dash:      return "Dash"
            case .dodge:     return "Dodge"
            case .help:      return "Help"
            case .endTurn:   return "End Turn"
            }
        }

        var icon: String {
            switch self {
            case .attack:    return "burst.fill"
            case .usePower:  return "sparkles"
            case .disengage: return "arrow.left.square.fill"
            case .dash:      return "arrow.up.right.circle.fill"
            case .dodge:     return "shield.fill"
            case .help:      return "hand.thumbsup.fill"
            case .endTurn:   return "hourglass.circle.fill"
            }
        }

        var needsTarget: Bool { self == .attack || self == .usePower }
    }

    // MARK: - Init

    init(combatState: CombatState, campaignId: String, apiClient: APIClient = APIClient()) {
        self.campaignId = campaignId
        self.apiClient  = apiClient
        self.currentTurnIndex = combatState.currentTurnIndex
        // Seed participants; assume index 0 is the player character
        self.participants = combatState.participants.enumerated().map { idx, c in
            CombatParticipant(
                id: c.id,
                name: c.name,
                hp: c.hp,
                maxHp: c.maxHp,
                ac: c.ac,
                initiative: c.initiative ?? (20 - idx * 2),
                conditions: c.conditions,
                isPlayer: idx == 0
            )
        }
        combatLog.append("⚔️ Combat started! Initiative rolled.")
    }

    // MARK: - Computed helpers

    var enemies: [CombatParticipant] { participants.filter { !$0.isPlayer } }

    var isPlayerTurn: Bool {
        guard participants.indices.contains(currentTurnIndex) else { return false }
        return participants[currentTurnIndex].isPlayer
    }

    var currentCombatant: CombatParticipant? {
        guard participants.indices.contains(currentTurnIndex) else { return nil }
        return participants[currentTurnIndex]
    }

    // MARK: - Actions

    func tapped(action: CombatActionType) {
        if action.needsTarget {
            pendingAction = action
            showTargetSheet = true
        } else {
            Task { await submit(action: action, targetId: nil) }
        }
    }

    func selectedTarget(_ participant: CombatParticipant) {
        guard let action = pendingAction else { return }
        showTargetSheet = false
        pendingAction = nil
        Task { await submit(action: action, targetId: participant.id.uuidString) }
    }

    func endTurn() {
        Task { await submit(action: .endTurn, targetId: nil) }
    }

    // MARK: - API

    private func submit(action: CombatActionType, targetId: String?) async {
        isSubmitting = true
        let body = CombatActionRequest(campaignId: campaignId, action: action.rawValue, targetId: targetId)
        do {
            let (response, _) = try await apiClient.post(
                CombatActionResponse.self,
                endpoint: "/api/game/combat/action",
                body: body
            )
            applyResponse(response, action: action)
        } catch {
            combatLog.append("⚠️ \(error.localizedDescription)")
        }
        isSubmitting = false
    }

    private func applyResponse(_ r: CombatActionResponse, action: CombatActionType) {
        // Update roster from server
        if let payloads = r.updatedParticipants {
            participants = payloads.map { p in
                CombatParticipant(
                    id: UUID(uuidString: p.id) ?? UUID(),
                    name: p.name, hp: p.hp, maxHp: p.maxHp,
                    ac: p.ac, initiative: p.initiative,
                    conditions: p.conditions, isPlayer: p.isPlayer
                )
            }
        }
        if let idx = r.currentTurnIndex { currentTurnIndex = idx }

        // Show dice overlay for attack/power
        if let d20 = r.d20Roll, let mod = r.modifier, let total = r.total {
            attackResult = AttackResult(
                hit: r.hit ?? false,
                d20Roll: d20, modifier: mod, total: total,
                damage: r.damageRoll, damageType: r.damageType
            )
            showDiceOverlay = true
        }

        // Log narration
        if let n = r.narration {
            combatLog.append(n)
            if combatLog.count > 20 { combatLog.removeFirst() }
            // Show enemy narration bar if it's not the player's turn
            if !isPlayerTurn { enemyNarration = n }
        }

        // Handle combat end
        if r.combatEnded == true {
            victory    = r.victory ?? false
            xpAwarded  = r.xpAwarded ?? 0
            combatEnded = true
        }
    }
}

// MARK: - CombatView (Main)

/// Full-screen combat overlay presented as a sheet when `combatState.active == true`.
struct CombatView: View {
    @StateObject private var vm: CombatViewModel
    @State private var pulseActive = false

    // Passed from parent so parent can flip combatState.active = false
    var onDismiss: () -> Void

    init(combatState: CombatState, campaignId: String, onDismiss: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: CombatViewModel(combatState: combatState, campaignId: campaignId))
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.92).ignoresSafeArea()

            VStack(spacing: 0) {
                // (1) Header
                combatHeader

                Divider().background(Color.borderSubtle)

                // (2) Initiative list
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 6) {
                        ForEach(Array(vm.participants.enumerated()), id: \.element.id) { idx, p in
                            initiativeRow(p, isCurrent: idx == vm.currentTurnIndex)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .frame(maxHeight: 260)

                Divider().background(Color.borderSubtle)

                // (3) Action buttons — only if player's turn
                if vm.isPlayerTurn && !vm.combatEnded {
                    actionGrid
                    Divider().background(Color.borderSubtle)
                }

                // (6) Combat log
                combatLogSection

                Spacer(minLength: 0)
            }

            // (5) Enemy narration bar (top overlay)
            if let narration = vm.enemyNarration {
                enemyNarrationBar(text: narration)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        Task {
                            try? await Task.sleep(for: .seconds(3))
                            withAnimation { vm.enemyNarration = nil }
                        }
                    }
            }

            // (3) Target selector bottom sheet
            if vm.showTargetSheet {
                Color.black.opacity(0.4).ignoresSafeArea()
                    .onTapGesture { withAnimation { vm.showTargetSheet = false } }
                targetSelectorSheet
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }

            // (7) Victory / Defeated banner
            if vm.combatEnded {
                combatEndBanner
            }
        }
        // (4) Dice roll overlay — attack resolution
        .sheet(isPresented: $vm.showDiceOverlay) {
            diceResultSheet
        }
        .animation(.easeInOut(duration: 0.3), value: vm.showTargetSheet)
        .animation(.easeInOut(duration: 0.3), value: vm.combatEnded)
        .animation(.easeInOut(duration: 0.25), value: vm.enemyNarration != nil)
        .onAppear {
            vm.onCombatEnded = onDismiss
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseActive = true
            }
        }
    }

    // MARK: - Header

    private var combatHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.shield.fill")
                .foregroundColor(.siithRed)
            Text("COMBAT")
                .font(.holoDisplay)
                .foregroundColor(.siithRed)
                .tracking(3)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 12))
                    .foregroundColor(.techOrange)
                Text("Round \(vm.currentTurnIndex / max(vm.participants.count, 1) + 1)")
                    .font(.dataReadout)
                    .foregroundColor(.techOrange)
            }

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.mutedText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Initiative Row

    @ViewBuilder
    private func initiativeRow(_ p: CombatViewModel.CombatParticipant, isCurrent: Bool) -> some View {
        HStack(spacing: 0) {
            // Animated orange left border for current turn
            RoundedRectangle(cornerRadius: 3)
                .fill(isCurrent ? Color.techOrange : Color.clear)
                .frame(width: 4)
                .shadow(color: isCurrent ? Color.techOrange.opacity(pulseActive ? 0.9 : 0.3) : .clear,
                        radius: isCurrent ? 6 : 0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseActive)
                .padding(.trailing, 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(p.name)
                        .font(.bodyText)
                        .fontWeight(isCurrent ? .semibold : .regular)
                        .foregroundColor(isCurrent ? .hologramBlue : .lightText)

                    if p.isPlayer {
                        Text("YOU")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.hologramBlue)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.hologramBlue.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }

                    Spacer()

                    // AC badge
                    Label("\(p.ac)", systemImage: "shield.fill")
                        .font(.dataReadout)
                        .foregroundColor(.mutedText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.spaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                // HP bar  — uses HPBar(current:maximum:)
                HPBar(current: p.hp, maximum: p.maxHp)

                // Conditions chips
                if !p.conditions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(p.conditions, id: \.self) { cond in
                                Text(cond)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.siithRed)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.siithRed.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(isCurrent ? Color.spaceCard.opacity(0.7) : Color.spaceCard.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isCurrent ? Color.techOrange.opacity(0.6) : Color.borderSubtle,
                    lineWidth: isCurrent ? 1.5 : 0.5
                )
        )
    }

    // MARK: - Action Buttons Grid

    private var actionGrid: some View {
        let actions = CombatViewModel.CombatActionType.allCases
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(actions, id: \.rawValue) { action in
                    actionButton(for: action)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .disabled(vm.isSubmitting)
    }

    @ViewBuilder
    private func actionButton(for action: CombatViewModel.CombatActionType) -> some View {
        let isEndTurn = action == .endTurn
        Button {
            if isEndTurn {
                vm.endTurn()
            } else {
                vm.tapped(action: action)
            }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: action.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isEndTurn ? .hologramBlue : .lightText)
                Text(action.label)
                    .font(.dataReadout)
                    .foregroundColor(isEndTurn ? .hologramBlue : .lightText)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(isEndTurn ? Color.holoBlueSubtle : Color.spaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isEndTurn ? Color.hologramBlue : Color.holoBlueSubtle,
                        lineWidth: 1
                    )
            )
        }
        .opacity(vm.isSubmitting ? 0.5 : 1)
    }

    // MARK: - Target Selector Sheet

    private var targetSelectorSheet: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.mutedText.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            HStack {
                Text("Select Target")
                    .font(.holoDisplay)
                    .foregroundColor(.lightText)
                Spacer()
                Button { withAnimation { vm.showTargetSheet = false } } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.mutedText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().background(Color.borderSubtle)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(vm.enemies) { enemy in
                        targetRow(enemy)
                    }
                }
                .padding(16)
            }
        }
        .background(Color.spacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private func targetRow(_ p: CombatViewModel.CombatParticipant) -> some View {
        let hpPct = Double(p.hp) / Double(max(p.maxHp, 1))
        let hpColor: Color = hpPct > 0.6 ? .saberGreen : (hpPct > 0.3 ? .techOrange : .siithRed)

        Button { vm.selectedTarget(p) } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(p.name)
                        .font(.bodyText)
                        .foregroundColor(.lightText)
                    HPBar(current: p.hp, maximum: p.maxHp)
                        .frame(maxWidth: 140)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(hpPct * 100))%")
                        .font(.dataReadout)
                        .fontWeight(.semibold)
                        .foregroundColor(hpColor)
                    Text("AC \(p.ac)")
                        .font(.dataReadout)
                        .foregroundColor(.mutedText)
                }
                Image(systemName: "chevron.right.circle.fill")
                    .foregroundColor(.siithRed.opacity(0.7))
            }
            .padding(12)
            .background(Color.spaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.siithRed.opacity(0.4), lineWidth: 1)
            )
        }
    }

    // MARK: - Dice Result Sheet  (Attack Resolution Overlay)

    @ViewBuilder
    private var diceResultSheet: some View {
        if let result = vm.attackResult {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 28) {
                    Spacer()

                    // d20 result
                    DiceRollOverlay(
                        sides: 20,
                        rolls: [result.d20Roll],
                        modifier: result.modifier,
                        total: result.total
                    )
                    .frame(maxWidth: .infinity)

                    // Hit / Miss banner
                    Text(result.hit ? "HIT" : "MISS")
                        .font(.system(size: 52, weight: .black, design: .monospaced))
                        .foregroundColor(result.hit ? .hologramBlue : .siithRed)
                        .shadow(color: result.hit ? .hologramBlue.opacity(0.6) : .siithRed.opacity(0.6), radius: 16)

                    // Damage roll (if hit)
                    if result.hit, let dmg = result.damage {
                        VStack(spacing: 6) {
                            Text("DAMAGE")
                                .font(.dataReadout)
                                .foregroundColor(.mutedText)
                                .tracking(2)
                            Text("\(dmg)")
                                .font(.system(size: 44, weight: .bold, design: .monospaced))
                                .foregroundColor(.techOrange)
                                .shadow(color: Color.techOrange.opacity(0.5), radius: 10)
                            if let dtype = result.damageType {
                                Text(dtype.uppercased())
                                    .font(.dataReadout)
                                    .foregroundColor(.mutedText)
                            }
                        }
                        .padding(16)
                        .background(Color.spaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Spacer()

                    Button("Continue") { vm.showDiceOverlay = false }
                        .font(.bodyText)
                        .fontWeight(.semibold)
                        .foregroundColor(.hologramBlue)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.holoBlueSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.bottom, 32)
                }
                .padding()
            }
        }
    }

    // MARK: - Enemy Narration Bar

    @ViewBuilder
    private func enemyNarrationBar(text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "person.crop.circle.fill.badge.exclamationmark")
                .foregroundColor(.siithRed)
            Text(text)
                .font(.dataReadout)
                .foregroundColor(.lightText)
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Color.spaceCard
                .overlay(Color.siithRed.opacity(0.08))
        )
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(.siithRed.opacity(0.6)),
            alignment: .bottom
        )
    }

    // MARK: - Combat Log

    private var combatLogSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("COMBAT LOG")
                    .font(.dataReadout)
                    .foregroundColor(.hologramBlue)
                    .tracking(2)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(vm.combatLog.suffix(5), id: \.self) { entry in
                        Text(entry)
                            .font(.system(size: 12))
                            .foregroundColor(.mutedText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
            .frame(maxHeight: 100)
        }
    }

    // MARK: - Combat End Banner

    @ViewBuilder
    private var combatEndBanner: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()

            VStack(spacing: 24) {
                // Icon
                Image(systemName: vm.victory ? "star.circle.fill" : "xmark.octagon.fill")
                    .font(.system(size: 72))
                    .foregroundColor(vm.victory ? .techOrange : .siithRed)
                    .shadow(color: vm.victory ? .techOrange.opacity(0.7) : .siithRed.opacity(0.6), radius: 20)
                    .scaleEffect(pulseActive ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulseActive)

                // Headline
                Text(vm.victory ? "VICTORY" : "DEFEATED")
                    .font(.system(size: 44, weight: .black, design: .monospaced))
                    .foregroundColor(vm.victory ? .techOrange : .siithRed)
                    .tracking(6)
                    .shadow(color: vm.victory ? .techOrange.opacity(0.5) : .siithRed.opacity(0.4), radius: 12)

                // XP award (victory only)
                if vm.victory && vm.xpAwarded > 0 {
                    VStack(spacing: 4) {
                        Text("EXPERIENCE AWARDED")
                            .font(.dataReadout)
                            .foregroundColor(.mutedText)
                            .tracking(2)
                        Text("+\(vm.xpAwarded) XP")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.saberGreen)
                    }
                    .padding(16)
                    .background(Color.spaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.saberGreen.opacity(0.4), lineWidth: 1)
                    )
                }

                Spacer().frame(height: 8)

                // Continue button
                Button(action: onDismiss) {
                    HStack(spacing: 8) {
                        Text("Continue Story")
                            .font(.bodyText)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.hologramBlue)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(Color.holoBlueSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.hologramBlue, lineWidth: 1)
                    )
                }
            }
            .padding(32)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - Preview

#Preview("Combat — Active") {
    CombatView(
        combatState: CombatState(
            active: true,
            currentTurnIndex: 0,
            participants: [
                Combatant(name: "Kael Ryn", hp: 28, maxHp: 35, ac: 16, initiative: 18),
                Combatant(name: "Sith Acolyte", hp: 22, maxHp: 30, ac: 15, initiative: 14, conditions: ["Stunned"]),
                Combatant(name: "Imperial Trooper", hp: 8, maxHp: 20, ac: 12, initiative: 9)
            ]
        ),
        campaignId: "preview-001",
        onDismiss: {}
    )
    .frame(height: 700)
    .background(Color.spacePrimary)
}

#Preview("Combat — Empty") {
    CombatView(
        combatState: CombatState(active: true, currentTurnIndex: 0, participants: []),
        campaignId: "preview-002",
        onDismiss: {}
    )
    .frame(height: 700)
    .background(Color.spacePrimary)
}
