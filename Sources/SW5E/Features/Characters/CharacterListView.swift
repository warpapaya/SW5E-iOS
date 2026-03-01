import SwiftUI

// MARK: - Character List View

/// The Characters tab root view — displays all characters with cards, search, swipe-to-delete,
/// context menus, empty state, and NavigationStack-owned destinations.
struct CharacterListView: View {
    // Parent callbacks — defaulted to no-ops; internal navigation handles all routing
    var onCharacterTap: (Character) -> Void = { _ in }
    var onAddCharacter: () -> Void = { }

    @StateObject private var viewModel = CharacterListViewModel()
    @State private var searchText = ""
    @State private var selectedCharacter: Character? = nil
    @State private var showingBuilder = false
    @State private var characterToDelete: Character? = nil

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.characters.isEmpty {
                    loadingView
                } else if filteredCharacters.isEmpty && searchText.isEmpty {
                    emptyStateView
                } else if filteredCharacters.isEmpty {
                    noSearchResultsView
                } else {
                    characterListView
                }
            }
            .background(Color.spacePrimary)
            .toolbarBackground(Color.spacePrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("Characters ⚔️")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingBuilder = true
                        onAddCharacter()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.veilGold)
                    }
                    .accessibilityLabel("Add character")
                }
            }
            .searchable(text: $searchText, prompt: "Search by name, species, or class")
            .refreshable { await viewModel.refreshCharacters() }
            // ── Navigation destinations ──────────────────────────────────────
            .navigationDestination(item: $selectedCharacter) { character in
                CharacterSheetView(character: character)
            }
            .navigationDestination(isPresented: $showingBuilder) {
                CharacterBuilderView()
            }
            .onChange(of: showingBuilder) { _, isShowing in
                // Reload characters when returning from the builder (new char may have been saved)
                if !isShowing {
                    Task { await viewModel.refreshCharacters() }
                }
            }
            // ── Delete confirmation alert ────────────────────────────────────
            .alert(
                "Delete Character?",
                isPresented: Binding(get: { characterToDelete != nil },
                                     set: { if !$0 { characterToDelete = nil } })
            ) {
                Button("Delete", role: .destructive) {
                    if let c = characterToDelete {
                        Task { await viewModel.deleteCharacter(c.id) }
                        characterToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) { characterToDelete = nil }
            } message: {
                if let c = characterToDelete {
                    Text("\"\(c.name)\" will be permanently deleted. This cannot be undone.")
                }
            }
        }
    }

    // MARK: - Loading State

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.veilGold)
                .scaleEffect(1.4)
            Text("Loading characters…")
                .font(.subheadline)
                .foregroundColor(.mutedText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Character List

    private var characterListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredCharacters) { character in
                    CharacterCardView(
                        character: character,
                        onTap: {
                            selectedCharacter = character
                            onCharacterTap(character)
                        },
                        onPlay: {
                            // Navigate to sheet — the Play FAB inside CharacterSheetView
                            // handles campaign selection
                            selectedCharacter = character
                        },
                        onDelete: {
                            characterToDelete = character
                        }
                    )
                    // Swipe-to-delete (destructive, requires confirmation via alert)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            characterToDelete = character
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Empty State (no characters)

    private var emptyStateView: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.veilGold.opacity(0.4))

            VStack(spacing: 10) {
                Text("No characters yet")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.lightText)

                Text("Create your first character to begin your journey in a galaxy far, far away.")
                    .font(.subheadline)
                    .foregroundColor(.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                showingBuilder = true
                onAddCharacter()
            } label: {
                Label("Create Character", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.veilGold, .veilGoldSubtle],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .veilGold.opacity(0.4), radius: 10)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - No Search Results

    private var noSearchResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.mutedText)
            Text("No characters matching \"\(searchText)\"")
                .font(.subheadline)
                .foregroundColor(.mutedText)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Computed Properties

    private var filteredCharacters: [Character] {
        let sorted = viewModel.characters.sorted { $0.lastModified > $1.lastModified }
        guard !searchText.isEmpty else { return sorted }
        let q = searchText.lowercased()
        return sorted.filter {
            $0.name.lowercased().contains(q) ||
            $0.species.lowercased().contains(q) ||
            $0.charClass.lowercased().contains(q)
        }
    }
}

// MARK: - Character Card View

/// Individual character card with class-keyed gradient, HP bar, and context menu.
struct CharacterCardView: View {
    let character: Character
    let onTap: () -> Void
    let onPlay: () -> Void
    let onDelete: () -> Void

    // Computed so it doesn't reference self before init
    private var classColor: CharacterClassColor {
        CharacterClassColor(rawValue: character.charClass) ?? .guardian
    }

    private var hpColor: Color {
        if character.hpPercentage < 0.25 { return .voidRed }
        if character.hpPercentage < 0.5  { return .veilPurple }
        return .veilGlow
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // ── Class icon ───────────────────────────────────────────────
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [classColor.gradientColors.0,
                                         classColor.gradientColors.1],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)
                        .shadow(color: classColor.gradientColors.0.opacity(0.45), radius: 8)

                    Image(systemName: classColor.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }

                // ── Info stack ───────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 6) {
                    // Name + level badge
                    HStack(alignment: .center, spacing: 6) {
                        Text(character.name)
                            .font(.headline)
                            .foregroundColor(.lightText)
                            .lineLimit(1)

                        if character.level >= 10 {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.veilPurple)
                        }

                        Spacer()

                        Text("Lv \(character.level)")
                            .font(.caption.weight(.heavy))
                            .foregroundColor(.spacePrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.veilGold))
                    }

                    // Species + class
                    HStack(spacing: 5) {
                        Text(character.species)
                            .font(.caption)
                            .foregroundColor(.veilGold)
                        Text("·")
                            .font(.caption)
                            .foregroundColor(.mutedText)
                        Text(character.charClass)
                            .font(.caption)
                            .foregroundColor(.mutedText)
                    }

                    // HP bar
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(hpColor)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.borderSubtle)
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        LinearGradient(
                                            colors: [hpColor, hpColor.opacity(0.55)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: geo.size.width * max(0, min(1, character.hpPercentage)),
                                        height: 6
                                    )
                            }
                        }
                        .frame(height: 10)

                        Text("\(character.currentHP)/\(character.maxHP)")
                            .font(.caption2.monospacedDigit())
                            .foregroundColor(hpColor)
                    }

                    // Last modified
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.mutedText)
                        Text(relativeTime(character.lastModified))
                            .font(.caption2)
                            .foregroundColor(.mutedText)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.mutedText)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.spaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(classColor.gradientColors.0.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        // ── Context menu ─────────────────────────────────────────────────────
        .contextMenu {
            Button { onTap() } label: {
                Label("View Sheet", systemImage: "doc.text.fill")
            }

            Button { onPlay() } label: {
                Label("Play", systemImage: "play.fill")
            }

            Divider()

            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Character List ViewModel

@MainActor
final class CharacterListViewModel: ObservableObject {
    @Published var characters: [Character] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?

    private let api = APIService.shared

    init() {
        // Pre-populate with demo data so UI is immediately usable
        characters = Character.demos
        Task { await loadCharacters() }
    }

    func loadCharacters() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await api.fetchCharacters()
            if !fetched.isEmpty { characters = fetched }
        } catch {
            // Keep demo data if already populated; only show error on explicit refresh
            if characters.isEmpty {
                characters = Character.demos
            }
        }
    }

    func refreshCharacters() async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let fetched = try await api.fetchCharacters()
            if !fetched.isEmpty { characters = fetched }
        } catch {
            errorMessage = "Server unavailable — showing demo characters"
            // Keep existing characters, don't wipe to empty
        }
    }

    func deleteCharacter(_ id: String) async {
        do {
            try await api.deleteCharacter(id: id)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                characters.removeAll { $0.id == id }
            }
        } catch {
            errorMessage = "Couldn't delete character: \(error.localizedDescription)"
        }
    }
}

// MARK: - Previews

#Preview("Characters — Empty") {
    CharacterListView()
        .preferredColorScheme(.dark)
}

#Preview("Character Card — Tidecaller") {
    CharacterCardView(
        character: Character(
            id: "preview-1",
            name: "Kael Voss",
            species: "Arion",
            charClass: "Tidecaller",
            level: 7,
            experiencePoints: 23_000,
            currentHP: 45,
            maxHP: 68,
            ac: 16,
            forcePoints: 12,
            lastModified: Date().addingTimeInterval(-3_600)
        ),
        onTap: {},
        onPlay: {},
        onDelete: {}
    )
    .padding()
    .background(Color.spacePrimary)
    .preferredColorScheme(.dark)
}

#Preview("Character Card — Low HP") {
    CharacterCardView(
        character: Character(
            id: "preview-2",
            name: "Zara Night",
            species: "Human",
            charClass: "Warden",
            level: 3,
            experiencePoints: 2_700,
            currentHP: 6,
            maxHP: 28,
            ac: 14,
            forcePoints: 0,
            lastModified: Date().addingTimeInterval(-86_400 * 2)
        ),
        onTap: {},
        onPlay: {},
        onDelete: {}
    )
    .padding()
    .background(Color.spacePrimary)
    .preferredColorScheme(.dark)
}
