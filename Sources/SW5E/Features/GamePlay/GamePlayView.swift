import SwiftUI

/// Main game play screen - the core Star Wars 5E experience.
struct GamePlayView: View {
    // MARK: - Environment & State

    @StateObject private var viewModel: GamePlayViewModel
    @ObservedObject private var soundManager = SoundManager.shared

    @State private var actionText = ""
    @State private var showCombatOverlay = false
    @State private var showCharacterDrawer = false
    @State private var narrativeScrollProxy: ScrollViewProxy?

    // MARK: - Computed Properties

    var currentLocation: String { viewModel.currentLocation }
    var isAIOnline: Bool { viewModel.isAIOnline }
    var canSendAction: Bool { viewModel.canSendAction }
    var suggestedChoices: [SuggestedChoice] {
        viewModel.campaign?.gameState.suggestedChoices ?? []
    }

    // MARK: - Initialization

    init(campaignId: String, apiClient: APIClient? = nil) {
        _viewModel = StateObject(wrappedValue: GamePlayViewModel(
            apiClient: apiClient ?? APIClient(),
            campaignId: campaignId
        ))
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
                            .id(viewModel.campaign?.gameState.history.count)
                        Divider().background(Color.borderSubtle)
                        choicesRow
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        Spacer()
                        actionInputBar
                    }

                    if viewModel.showSessionSummaryBanner {
                        sessionSummaryBanner
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }

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

                if showCharacterDrawer, let campaign = viewModel.campaign {
                    CharacterSidebarDrawer(
                        campaign: campaign,
                        isPresented: $showCharacterDrawer,
                        character: viewModel.campaign?.gameState.activeCharacter
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .onAppear {
                Task { await viewModel.loadCampaign() }
                if let character = viewModel.campaign?.gameState.activeCharacter {
                    viewModel.checkForceUserStatus(character: character)
                }
            }
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

            Button(action: {}) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
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

    @ViewBuilder private var narrativeScrollView: some View {
        ScrollViewReader { proxy in
            ScrollViewShowsIndicators {
                LazyVStack(spacing: 0) {
                    ForEach(narrativeEntries) { entry in
                        historyEntry(for: entry)
                            .id(entry.id)
                    }
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollPositionPreferenceKey.self,
                            value: geo.frame(in: .named("gameplay-scroll")).minY
                        )
                    }
                    .frame(height: 0)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: narrativeEntries.count)
            .onAppear { narrativeScrollProxy = proxy }
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
        case .sessionSummary: sessionSummaryBannerContent(text: entry.content)
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
        HStack(alignment: .top, spacing: 8) {
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Text(content)
                    .font(.bodyText)
                    .foregroundColor(.lightText)
                    .lineSpacing(4)
                    .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .background(Color.spaceCard.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.techOrange, lineWidth: 2)
                .padding(-2)
        )
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

    // MARK: - Choices Row

    @ViewBuilder private var choicesRow: some View {
        ScrollViewShowsIndicators(.horizontal) {
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

                Button(action: sendAction) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(canSendAction ? Color.hologramBlue : Color.mutedText)
                        .padding(4)
                }
                .disabled(!canSendAction)
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
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "book.closed").foregroundColor(.hologramBlue)
                Text("Previous Session Recap").font(.dataReadout).foregroundColor(.lightText)
                Spacer()
                Button(action: viewModel.dismissSessionSummary) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.mutedText)
                }
            }
            .padding(12)
            Divider().background(Color.borderSubtle)
        }
        .background(Color.spaceCard.opacity(0.9))
    }

    @ViewBuilder private func sessionSummaryBannerContent(text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "book.closed").foregroundColor(.hologramBlue)
                Text("Previous Session Recap").font(.dataReadout).foregroundColor(.lightText)
                Spacer()
                Button(action: viewModel.dismissSessionSummary) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.mutedText)
                }
            }
            Text(text).font(.bodyText).foregroundColor(.lightText).padding(.horizontal, 12)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Loading Indicator

    @ViewBuilder private var loadingIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(Color.hologramBlue.opacity(0.7))
                    .frame(width: 8, height: 8)
                    .scaleEffect(viewModel.isProcessingAction ? 1.0 : 0.5)
                    .opacity(viewModel.isProcessingAction ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: viewModel.isProcessingAction)
            }
        }
    }

    // MARK: - Actions

    private func sendAction() {
        guard canSendAction, !actionText.isEmpty else { return }
        soundManager.playDiceRoll()
        Task {
            do {
                try await viewModel.submitAction(
                    actionText: actionText,
                    selectedChoiceId: viewModel.selectedChoiceId
                )
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    actionText = ""
                    viewModel.selectedChoiceId = nil
                }
            } catch {
                print("Action failed: \(error)")
            }
        }
    }

    private func selectQuickAction(_ text: String) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            actionText = text
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
