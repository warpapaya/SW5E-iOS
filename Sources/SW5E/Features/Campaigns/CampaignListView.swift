import SwiftUI

// MARK: - Campaign List View

/// Root view of the Play tab.
/// Sections: "Resume Campaign" + "New Campaign" (template picker).
/// Nav bar includes pulsing AI-status dot.
struct CampaignListView: View {

    @StateObject private var viewModel = CampaignStartViewModel()

    // Sheet / navigation state
    @State private var showTemplatePicker   = false
    @State private var showCharacterPicker  = false
    @State private var selectedTemplate: CampaignTemplate?
    @State private var navigateToCampaignId: String?

    var body: some View {
        NavigationStack {
            contentScroll
                .overlay {
                    if viewModel.isLoadingCampaigns {
                        Color.spacePrimary
                            .ignoresSafeArea()
                            .overlay {
                                ProgressView().tint(.hologramBlue)
                            }
                    }
                }
                .overlay {
                    if viewModel.isStarting { generatingOverlay }
                }
                .background(Color.spacePrimary)
                .toolbarBackground(Color.spacePrimary, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("Play")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    AIStatusIndicator(isAvailable: viewModel.aiAvailable) {
                        Task { await viewModel.checkAIStatus() }
                    }
                }
            }
            .task { await viewModel.loadAll() }
            .refreshable { await viewModel.loadAll() }
            // Template picker sheet
            .sheet(isPresented: $showTemplatePicker) {
                TemplatePickerView(
                    onSelect: { template in
                        selectedTemplate = template
                        showTemplatePicker = false
                        showCharacterPicker = true
                    },
                    onDismiss: { showTemplatePicker = false }
                )
            }
            // Character picker sheet
            .sheet(isPresented: $showCharacterPicker) {
                CharacterPickerSheet(
                    characters: viewModel.characters,
                    onSelect: { character in
                        showCharacterPicker = false
                        Task {
                            await viewModel.startCampaign(
                                templateId: selectedTemplate?.id,
                                characterId: character.id
                            )
                        }
                    },
                    onCreateNew: {
                        showCharacterPicker = false
                        // TODO: push CharacterBuilderView — handled by parent nav
                    },
                    onDismiss: { showCharacterPicker = false }
                )
            }
            // Navigate to GamePlayView after campaign starts/resumes
            .navigationDestination(item: $viewModel.launchedCampaignId) { campaignId in
                // Stub — GamePlayView is defined in Features/GamePlay/
                GamePlayLaunchView(campaignId: campaignId)
            }
            // Error banner
            .safeAreaInset(edge: .bottom) {
                if let err = viewModel.errorMessage {
                    errorBanner(err)
                }
            }
        }
    }

    // MARK: - Main Scroll Content

    private var contentScroll: some View {
        ScrollView {
            // VStack (not LazyVStack) — iOS 26 lazy containers need explicit frame context
            VStack(alignment: .leading, spacing: 24) {

                // ── SECTION 1: Resume Campaign ──────────────────────────────
                if !viewModel.savedCampaigns.isEmpty {
                    sectionHeader("Resume Campaign", icon: "arrow.clockwise.circle.fill")

                    ForEach(viewModel.savedCampaigns) { summary in
                        SavedCampaignCard(summary: summary) {
                            viewModel.resumeCampaign(summary)
                        }
                        .padding(.horizontal)
                    }
                }

                // ── SECTION 2: New Campaign ─────────────────────────────────
                sectionHeader("New Campaign", icon: "plus.circle.fill")

                newCampaignButton
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 12)
            .padding(.bottom, 100)  // breathing room above floating tab bar
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.hologramBlue)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.lightText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 4)
    }

    // MARK: - New Campaign Button

    private var newCampaignButton: some View {
        Button { showTemplatePicker = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [.hologramBlue, .holoBlueSubtle],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.lightText)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Start New Campaign")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.lightText)
                    Text("Choose a template or go freeform sandbox")
                        .font(.caption)
                        .foregroundColor(.mutedText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.hologramBlue)
            }
            .padding(14)
            .background(Color.spaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.hologramBlue.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Generating Overlay

    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()

            VStack(spacing: 20) {
                HoloSpinner()

                Text("Generating opening scene...")
                    .font(.headline)
                    .foregroundColor(.hologramBlue)

                Text("The AI Game Master is building your world")
                    .font(.caption)
                    .foregroundColor(.mutedText)
            }
            .padding(32)
            .background(Color.spaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.hologramBlue.opacity(0.5), lineWidth: 1)
            )
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.techOrange)
            Text(message)
                .font(.caption)
                .foregroundColor(.lightText)
            Spacer()
            Button("Dismiss") {
                viewModel.errorMessage = nil
            }
            .font(.caption)
            .foregroundColor(.hologramBlue)
        }
        .padding(12)
        .background(Color.spaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.siithRed.opacity(0.4), lineWidth: 1))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// MARK: - Saved Campaign Card

struct SavedCampaignCard: View {
    let summary: CampaignSummary
    let onResume: () -> Void

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: summary.lastPlayedAt, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 14) {
            // Campaign icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [.hologramBlue.opacity(0.6), .holoBlueSubtle],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                Image(systemName: "map.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.lightText)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(summary.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.lightText)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                        .foregroundColor(.hologramBlue)
                    Text(summary.characterName)
                        .font(.caption)
                        .foregroundColor(.hologramBlue)
                }

                HStack(spacing: 10) {
                    Label(summary.currentLocation, systemImage: "mappin")
                        .font(.caption2)
                        .foregroundColor(.mutedText)
                        .lineLimit(1)

                    Text("·")
                        .foregroundColor(.mutedText)
                        .font(.caption2)

                    Label(relativeDate, systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.mutedText)
                }
            }

            Spacer()

            // Resume button
            Button(action: onResume) {
                Text("Resume")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.spacePrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.hologramBlue)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.spaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Holo Spinner

/// Animated hologram-style spinner used on the generating overlay.
private struct HoloSpinner: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.hologramBlue.opacity(0.2), lineWidth: 4)
                .frame(width: 56, height: 56)

            Circle()
                .trim(from: 0, to: 0.72)
                .stroke(
                    LinearGradient(
                        colors: [.hologramBlue, .hologramBlue.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 56, height: 56)
                .rotationEffect(.degrees(rotation))

            Image(systemName: "sparkles")
                .font(.system(size: 18))
                .foregroundColor(.hologramBlue)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - GamePlay Launch Stub

/// Thin wrapper so NavigationDestination compiles without importing GamePlayView.
/// Replace with `GamePlayView(campaignId:)` once the features are wired up.
struct GamePlayLaunchView: View {
    let campaignId: String
    var body: some View {
        GamePlayView(campaignId: campaignId)
    }
}

// MARK: - Preview

#Preview("Campaign List — Empty") {
    CampaignListView()
}

#Preview("Saved Campaign Card") {
    SavedCampaignCard(
        summary: CampaignSummary(
            id: "c1",
            title: "Shadows of the Sith",
            characterName: "Kael Voss",
            characterClass: "Guardian",
            lastPlayedAt: Date().addingTimeInterval(-3600 * 6),
            currentLocation: "Coruscant, Level 1313",
            isActive: true
        ),
        onResume: {}
    )
    .padding()
    .background(Color.spacePrimary)
    .preferredColorScheme(.dark)
}
