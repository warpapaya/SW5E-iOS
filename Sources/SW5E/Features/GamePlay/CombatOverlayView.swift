import SwiftUI

/// Combat tracker overlay displayed as a sheet when combat is active.
struct CombatOverlayView: View {
    // combatState is a value type now — pass by value
    var combatState: CombatState
    let soundManager: SoundManager
    let onDismiss: () -> Void
    let onBlasterShot: () -> Void

    @State private var showTargetSelector = false
    @State private var selectedTargetId: UUID? = nil
    @State private var currentActionType: CombatActionType? = nil
    @State private var localCombatState: CombatState

    init(combatState: CombatState, soundManager: SoundManager, onDismiss: @escaping () -> Void, onBlasterShot: @escaping () -> Void) {
        self.combatState = combatState
        self.soundManager = soundManager
        self.onDismiss = onDismiss
        self.onBlasterShot = onBlasterShot
        _localCombatState = State(initialValue: combatState)
    }

    enum CombatActionType {
        case attack, usePower, disengage, dash, dodge, help
    }

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.85).ignoresSafeArea()

                VStack(spacing: 0) {
                    combatHeader
                    Divider().background(Color.borderSubtle)
                    initiativeList
                    Divider().background(Color.borderSubtle)
                    actionButtonsGrid
                    Divider().background(Color.borderSubtle)
                    combatLog
                }
                .padding(16)

                if showTargetSelector, let actionType = currentActionType {
                    targetSelectorSheet(for: actionType)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Combat Header

    @ViewBuilder private var combatHeader: some View {
        HStack(spacing: 12) {
            Text("⚔️ COMBAT")
                .font(.holoDisplay)
                .foregroundColor(.voidRed)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "timer").foregroundColor(.veilPurple)
                Text("Turn \(localCombatState.currentTurnIndex + 1)")
                    .font(.dataReadout)
                    .foregroundColor(.lightText)
            }

            Button(action: endCombat) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.mutedText)
                    .font(.system(size: 24))
            }
        }
        .padding(16)
    }

    // MARK: - Initiative List

    @ViewBuilder private var initiativeList: some View {
        ScrollViewShowsIndicators {
            VStack(spacing: 8) {
                ForEach(Array(localCombatState.participants.enumerated()), id: \.element.id) { index, participant in
                    initiativeRow(participant: participant, isCurrentTurn: index == localCombatState.currentTurnIndex)
                        .id(participant.id)
                }
            }
        }
    }

    @ViewBuilder private func initiativeRow(participant: Combatant, isCurrentTurn: Bool) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(isCurrentTurn ? Color.veilPurple : Color.clear)
                .frame(width: 6)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.veilPurple.opacity(0.5), lineWidth: 2))
                .animation(.easeInOut(duration: 0.3), value: isCurrentTurn)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(participant.name)
                        .font(.bodyText)
                        .foregroundColor(isCurrentTurn ? Color.veilGold : .lightText)

                    if isCurrentTurn {
                        Circle()
                            .fill(Color.veilPurple)
                            .frame(width: 6, height: 6)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCurrentTurn)
                    }
                }

                HStack(spacing: 8) {
                    HPBar(currentHp: participant.hp, maxHp: participant.maxHp, size: 8)

                    Text("AC \(participant.ac)")
                        .font(.dataReadout)
                        .foregroundColor(.lightText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.spaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                if !participant.conditions.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(participant.conditions, id: \.self) { condition in
                            Text(condition)
                                .font(.dataReadout)
                                .foregroundColor(.voidRed)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.voidRed.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .background(isCurrentTurn ? Color.spaceCard.opacity(0.6) : Color.spaceCard.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Action Buttons Grid

    @ViewBuilder private var actionButtonsGrid: some View {
        ScrollViewShowsIndicators(.horizontal) {
            HStack(spacing: 12) {
                combatActionButton(icon: "sword", label: "Attack")   { prepareAction(.attack) }
                combatActionButton(icon: "sparkles", label: "Power") { prepareAction(.usePower) }
                combatActionButton(icon: "arrow.left.square.fill", label: "Disengage") { submitCombatAction("disengage") }
                combatActionButton(icon: "arrow.up.right", label: "Dash")    { submitCombatAction("dash") }
                combatActionButton(icon: "shield.fill", label: "Dodge")      { submitCombatAction("dodge") }
                combatActionButton(icon: "hand.thumbsup.fill", label: "Help") { submitCombatAction("help") }

                Button(action: endTurn) {
                    VStack(spacing: 4) {
                        Image(systemName: "hourglass.bottomhalf.filled").font(.system(size: 20))
                        Text("End Turn").font(.dataReadout)
                    }
                    .foregroundColor(.veilGold)
                    .padding(12)
                    .background(Color.spaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.veilGoldSubtle, lineWidth: 1))
                }
            }
        }
    }

    @ViewBuilder private func combatActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 18))
                Text(label).font(.dataReadout).foregroundColor(.lightText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.spaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.veilGoldSubtle, lineWidth: 1))
        }
    }

    // MARK: - Combat Log

    @ViewBuilder private var combatLog: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("COMBAT LOG")
                .font(.dataReadout)
                .foregroundColor(.veilGold)

            ScrollViewShowsIndicators(.vertical) {
                VStack(spacing: 6) {
                    ForEach(combatLogEntries.prefix(5), id: \.self) { logEntry in
                        Text(logEntry)
                            .font(.bodyText)
                            .foregroundColor(.lightText)
                            .lineSpacing(2)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(16)
    }

    private var combatLogEntries: [String] {
        ["Combat started!", "Initiative rolled.", "Round 1 beginning."]
    }

    // MARK: - Target Selector

    @ViewBuilder private func targetSelectorSheet(for actionType: CombatActionType) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("Select Target")
                    .font(.holoDisplay)
                    .foregroundColor(.lightText)
                Spacer()
                Button(action: dismissTargetSelector) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.mutedText)
                }
            }
            .padding(16)

            Divider().background(Color.borderSubtle)

            ScrollViewShowsIndicators {
                VStack(spacing: 8) {
                    ForEach(localCombatState.participants, id: \.id) { participant in
                        targetButton(participant: participant, isSelected: selectedTargetId == participant.id) {
                            setSelectedTarget(participant.id)
                        }
                    }
                }
                .padding(16)
            }

            Button("Cancel") { dismissTargetSelector() }
                .font(.dataReadout)
                .foregroundColor(.mutedText)
                .padding(16)
        }
        .background(Color.spacePrimary)
    }

    @ViewBuilder private func targetButton(participant: Combatant, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(participant.name)
                        .font(.bodyText)
                        .foregroundColor(isSelected ? Color.veilGold : .lightText)
                    HPBar(currentHp: participant.hp, maxHp: participant.maxHp, size: 6)
                }
                Spacer()
                Text("\(Int(Double(participant.hp) / Double(max(1, participant.maxHp)) * 100))%")
                    .font(.dataReadout)
                    .foregroundColor(healthColor(for: participant))
            }
            .padding(12)
            .background(isSelected ? Color.spaceCard.opacity(0.8) : Color.spaceCard.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func healthColor(for participant: Combatant) -> Color {
        let pct = Double(participant.hp) / Double(max(1, participant.maxHp))
        if pct > 0.6 { return .veilGlow }
        if pct > 0.3 { return .veilPurple }
        return .voidRed
    }

    // MARK: - Actions

    private func prepareAction(_ actionType: CombatActionType) {
        currentActionType = actionType
        if actionType == .attack { soundManager.playBlasterShot() }
        showTargetSelector = true
    }

    private func dismissTargetSelector() {
        withAnimation(.easeOut(duration: 0.2)) {
            showTargetSelector = false
            selectedTargetId = nil
            currentActionType = nil
        }
    }

    private func setSelectedTarget(_ targetId: UUID) {
        selectedTargetId = targetId
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showTargetSelector = false
        }
    }

    private func submitCombatAction(_ actionName: String) {
        soundManager.playDiceRoll()
        print("Combat action: \(actionName)")
    }

    private func endTurn() {
        soundManager.playDiceRoll()
        withAnimation(.easeInOut(duration: 0.5)) {
            localCombatState.currentTurnIndex = (localCombatState.currentTurnIndex + 1) % max(1, localCombatState.participants.count)
        }
    }

    private func endCombat() {
        withAnimation(.easeInOut(duration: 0.3)) {
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview("Combat Overlay") {
    CombatOverlayView(
        combatState: CombatState(active: true, currentTurnIndex: 0, participants: [
            Combatant(name: "Player Character", hp: 28, maxHp: 35, ac: 16),
            Combatant(name: "Voidshaper Warrior",     hp: 42, maxHp: 50, ac: 18),
            Combatant(name: "Sovereignty Vanguard", hp: 12, maxHp: 20, ac: 14)
        ]),
        soundManager: SoundManager.shared,
        onDismiss: { },
        onBlasterShot: { }
    )
}
