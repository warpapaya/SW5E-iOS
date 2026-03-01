import SwiftUI

/// Main game play screen - the core Echoveil experience.
struct GamePlayView: View {
    // MARK: - Environment & State

    @StateObject private var viewModel: GamePlayViewModel
    @ObservedObject private var soundManager = SoundManager.shared

    @State private var actionText = ""
    @State private var showCombatOverlay = false
    @State private var showCharacterDrawer = false
    @State private var showSettingsSheet = false
    @State private var narrativeScrollProxy: ScrollViewProxy?

    // MARK: - Computed Properties

    var currentLocation: String { viewModel.currentLocation }
    var isAIOnline: Bool { viewModel.isAIOnline }
    var canSendAction: Bool { viewModel.canSendAction }
    var suggestedChoices: [SuggestedChoice] {
        viewModel.campaign?.gameState.suggestedChoices ?? []
    }

    // MARK: - Initialization

    init(campaignId: String) {
        _viewModel = StateObject(wrappedValue: GamePlayViewModel(campaignId: campaignId))
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .bottom) {
                ZStack {
                    Color.spacePrimary.ignoresSafeArea()

                    VStack(spacing: 0) {
                        topBar
                        Divider().background(Color.borderSubtle)
                        narrativeScrollView
                        Divider().background(Color.borderSubtle)
                        choicesRow
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        Spacer()
                        actionInputBar
                    }

                    // Session summary banner (top)
                    if viewModel.showSessionSummaryBanner {
                        VStack {
                            sessionSummaryBanner
                                .transition(.move(edge: .top).combined(with: .opacity))
                            Spacer()
                        }
                    }

                    // XP Toast
                    if viewModel.showXPToast {
                        VStack {
                            Spacer()
                            xpToast
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .padding(.bottom, 120)
                        }
                    }
                }

                // Combat overlay
                if let campaign = viewModel.campaign, campaign.gameState.combatState.active {
                    CombatOverlayView(
                        combatState: campaign.gameState.combatState,
                        soundManager: soundManager,
                        onDismiss: { showCombatOverlay = false },
                        onBlasterShot: { soundManager.playBlasterShot() }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom)
                    ))
                }

                // Character drawer
                if showCharacterDrawer, let campaign = viewModel.campaign {
                    CharacterSidebarDrawer(
                        campaign: campaign,
                        isPresented: $showCharacterDrawer,
                        character: viewModel.campaign?.gameState.activeCharacter
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.showXPToast)
            .animation(.spring(response: 0.35), value: viewModel.showSessionSummaryBanner)
            .onAppear {
                Task { await viewModel.loadCampaign() }
            }
        }
        // Campaign settings sheet
        .sheet(isPresented: $showSettingsSheet) {
            CampaignSettingsSheet(viewModel: viewModel)
        }
    }

    // MARK: - Top Bar

    @ViewBuilder private var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.campaign?.title ?? "Loading...")
                    .font(.holoDisplay)
                    .foregroundColor(.hologramBlue)

                HStack(spacing: 6) {
                    Text(currentLocation)
                        .font(.dataReadout)
                        .foregroundColor(.lightText)

                    Circle()
                        .fill(isAIOnline ? Color.saberGreen : Color.siithRed)
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: isAIOnline)
                }
            }

            Spacer()

            // Undo button
            Button {
                Task { await viewModel.undoLastAction() }
            } label: {
                Image(systemName: viewModel.isUndoing ? "clock.arrow.circlepath" : "arrow.uturn.backward")
                    .font(.system(size: 18))
                    .foregroundColor(viewModel.isUndoing ? .mutedText : .hologramBlue)
                    .padding(8)
                    .background(Color.spaceCard)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.holoBlueSubtle, lineWidth: 1))
            }
            .disabled(viewModel.isUndoing)

            // Settings button
            Button(action: { showSettingsSheet = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.hologramBlue)
                    .padding(8)
                    .background(Color.spaceCard)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.holoBlueSubtle, lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Narrative Scroll View
    // Use VStack (not LazyVStack) — iOS 26 LazyVStack inside NavigationStack is unreliable

    @ViewBuilder private var narrativeScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(narrativeEntries) { entry in
                        historyEntry(for: entry)
                            .id(entry.id)
                            .padding(.bottom, 8)
                    }

                    if viewModel.isProcessingAction {
                        thinkingIndicator
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
            .onChange(of: narrativeEntries.count) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isProcessingAction) { _, isProcessing in
                if isProcessing {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            .onAppear {
                narrativeScrollProxy = proxy
                // Scroll to bottom on initial load
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    private var narrativeEntries: [GameHistoryEntry] {
        viewModel.campaign?.gameState.history ?? []
    }

    // MARK: - History Entry Rendering

    @ViewBuilder private func historyEntry(for entry: GameHistoryEntry) -> some View {
        switch entry.type {
        case .gmNarration:    gmNarrationCard(content: entry.content)
        case .playerAction:   playerActionCard(content: entry.content)
        case .combatResult:   combatResultCard(content: entry.content)
        case .sessionSummary: sessionSummaryCard(content: entry.content)
        }
    }

    @ViewBuilder private func gmNarrationCard(content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(content)
                .font(.bodyText)
                .foregroundColor(.lightText)
                .italic()
                .lineSpacing(4)
                .padding(.vertical, 8)
        }
        .padding(16)
        .background(Color.spaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.hologramBlue, lineWidth: 3)
                .padding(-3)
        )
        .padding(.horizontal, 16)
    }

    @ViewBuilder private func playerActionCard(content: String) -> some View {
        HStack {
            Spacer()
            Text(content)
                .font(.bodyText)
                .foregroundColor(.lightText)
                .lineSpacing(4)
                .padding(14)
                .background(Color.spaceCard.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.techOrange, lineWidth: 2)
                )
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder private func combatResultCard(content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("⚔️ COMBAT UPDATE")
                .font(.dataReadout)
                .foregroundColor(.siithRed)
            Text(content)
                .font(.bodyText)
                .foregroundColor(.lightText)
                .italic()
        }
        .padding(16)
        .background(Color.spaceCard.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.siithRed, lineWidth: 3)
                .padding(-3)
        )
        .padding(.horizontal, 16)
    }

    @ViewBuilder private func sessionSummaryCard(content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "book.closed.fill")
                    .foregroundColor(.hologramBlue)
                Text("SESSION RECAP")
                    .font(.dataReadout)
                    .foregroundColor(.hologramBlue)
            }
            Text(content)
                .font(.bodyText)
                .foregroundColor(.lightText)
        }
        .padding(16)
        .background(Color.spaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.hologramBlue.opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Thinking Indicator

    @ViewBuilder private var thinkingIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "ellipsis")
                .font(.title3)
                .foregroundColor(.hologramBlue)
                .symbolEffect(.variableColor.iterative, options: .repeating)
            Text("AI Game Master is thinking…")
                .font(.caption)
                .foregroundColor(.mutedText)
            Spacer()
        }
        .padding(12)
        .background(Color.spaceCard.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - XP Toast

    @ViewBuilder private var xpToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundColor(.saberGreen)
            Text("+\(viewModel.xpToastAmount) XP")
                .font(.headline.weight(.bold))
                .foregroundColor(.saberGreen)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.spaceCard)
                .shadow(color: Color.saberGreen.opacity(0.4), radius: 12)
        )
        .overlay(Capsule().strokeBorder(Color.saberGreen.opacity(0.5), lineWidth: 1))
    }

    // MARK: - Choices Row

    @ViewBuilder private var choicesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestedChoices) { choice in
                    ChoiceChip(
                        text: choice.text,
                        emoji: choice.emoji,
                        isSelected: viewModel.selectedChoiceId == choice.id,
                        onTap: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                viewModel.selectedChoiceId = choice.id
                                actionText = choice.text
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Action Input Bar

    @ViewBuilder private var actionInputBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                quickActionButton(icon: "sword", label: "Attack") {
                    selectQuickAction("⚔️ Attack")
                    soundManager.playBlasterShot()
                }
                quickActionButton(icon: "bubble.left.fill", label: "Talk") { selectQuickAction("💬 Talk") }
                quickActionButton(icon: "magnifyingglass", label: "Investigate") { selectQuickAction("🔍 Investigate") }
                quickActionButton(icon: "arrow.up.right", label: "Move") { selectQuickAction("🏃 Move") }
                quickActionButton(icon: "sparkles", label: "Power") { selectQuickAction("✨ Use Power") }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Divider().background(Color.borderSubtle)

            HStack(spacing: 12) {
                TextField("What do you do?", text: $actionText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.bodyText)
                    .foregroundColor(.lightText)
                    .padding(12)
                    .background(Color.spaceCard)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.borderSubtle, lineWidth: 1))
                    .lineLimit(1...4)

                Button(action: sendAction) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(canSendAction && !actionText.isEmpty ? Color.hologramBlue : Color.mutedText)
                        .padding(4)
                }
                .disabled(!canSendAction || actionText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.spacePrimary)
    }

    @ViewBuilder private func quickActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.dataReadout)
                    .foregroundColor(.lightText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.spaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.holoBlueSubtle, lineWidth: 1))
        }
    }

    // MARK: - Session Summary Banner

    @ViewBuilder private var sessionSummaryBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "book.closed").foregroundColor(.hologramBlue)
            Text(viewModel.sessionSummaryText)
                .font(.caption)
                .foregroundColor(.lightText)
                .lineLimit(2)
            Spacer()
            Button {
                Task { await viewModel.fetchSessionSummary() }
                viewModel.dismissSessionSummary()
            } label: {
                Text("Load")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.hologramBlue)
            }
            Button(action: viewModel.dismissSessionSummary) {
                Image(systemName: "xmark.circle.fill").foregroundColor(.mutedText)
            }
        }
        .padding(12)
        .background(Color.spaceCard.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    // MARK: - Actions

    private func sendAction() {
        guard canSendAction, !actionText.isEmpty else { return }
        soundManager.playDiceRoll()
        let text = actionText
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            actionText = ""
            viewModel.selectedChoiceId = nil
        }
        Task {
            await viewModel.submitAction(actionText: text)
        }
    }

    private func selectQuickAction(_ text: String) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            actionText = text
        }
    }
}

// MARK: - Campaign Settings Sheet

struct CampaignSettingsSheet: View {
    @ObservedObject var viewModel: GamePlayViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var draft_difficulty: DifficultyLevel = .normal
    @State private var draft_gmStyle: GMStyle = .cinematic

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Difficulty", selection: $draft_difficulty) {
                        ForEach(DifficultyLevel.allCases, id: \.self) { level in
                            Label(level.displayName, systemImage: level.icon).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.spaceCard)
                } header: {
                    Label("Difficulty", systemImage: "shield.fill")
                        .foregroundColor(.hologramBlue)
                }

                Section {
                    Picker("GM Style", selection: $draft_gmStyle) {
                        ForEach(GMStyle.allCases, id: \.self) { style in
                            Label(style.displayName, systemImage: style.icon).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.spaceCard)
                } header: {
                    Label("Narrative Style", systemImage: "film.fill")
                        .foregroundColor(.hologramBlue)
                } footer: {
                    Text("Cinematic = epic drama · Gritty = dark & realistic · Comedic = lighthearted")
                        .foregroundColor(.mutedText)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.spacePrimary.ignoresSafeArea())
            .navigationTitle("Campaign Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.hologramBlue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        Task {
                            await viewModel.applySettings(difficulty: draft_difficulty, gmStyle: draft_gmStyle)
                            dismiss()
                        }
                    }
                    .foregroundColor(.saberGreen)
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            draft_difficulty = viewModel.selectedDifficulty
            draft_gmStyle    = viewModel.selectedGMStyle
        }
    }
}

// MARK: - ChoiceChip

private struct ChoiceChip: View {
    let text: String
    let emoji: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if let emoji { Text(emoji) }
                Text(text)
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.spacePrimary : Color.lightText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.hologramBlue : Color.spaceCard)
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(
                    isSelected ? Color.hologramBlue : Color.holoBlueSubtle,
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("GamePlay View") {
    GamePlayView(campaignId: "test-campaign-123")
}
