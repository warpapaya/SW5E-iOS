import SwiftUI

// MARK: - Character Picker Sheet

/// Bottom sheet presented when starting a new campaign.
/// Lists available characters with class icon + level. 
/// 'Create New Character' shortcut at bottom.
struct CharacterPickerSheet: View {
    let characters: [Character]
    let onSelect: (Character) -> Void
    let onCreateNew: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if characters.isEmpty {
                    emptyState
                } else {
                    characterList
                }

                createNewButton
            }
            .background(Color.spacePrimary.ignoresSafeArea())
            .navigationTitle("Choose Your Character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                        .foregroundColor(.veilGold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    // MARK: - Character List

    private var characterList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(characters) { character in
                    CharacterPickerRow(character: character) {
                        onSelect(character)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.slash")
                .font(.system(size: 52))
                .foregroundColor(.veilGold.opacity(0.4))
            Text("No characters yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.lightText)
            Text("Create a character first to start a campaign")
                .font(.subheadline)
                .foregroundColor(.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Create New CTA

    private var createNewButton: some View {
        Button(action: onCreateNew) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("Create New Character")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.lightText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.veilGold, .veilGoldSubtle],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .padding(.top, 8)
    }
}

// MARK: - Character Picker Row

private struct CharacterPickerRow: View {
    let character: Character
    let onSelect: () -> Void

    @State private var isPressed = false

    private var classColor: CharacterClassColor {
        CharacterClassColor(rawValue: character.charClass) ?? .guardian
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Class icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [classColor.gradientColors.0, classColor.gradientColors.1],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)

                    Image(systemName: classColor.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.lightText)
                }

                // Name + class + level
                VStack(alignment: .leading, spacing: 4) {
                    Text(character.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.lightText)

                    HStack(spacing: 8) {
                        Text(character.species)
                            .font(.caption)
                            .foregroundColor(.veilGold)

                        Text("·")
                            .foregroundColor(.mutedText)

                        Text(character.charClass)
                            .font(.caption)
                            .foregroundColor(.lightText.opacity(0.7))
                    }
                }

                Spacer()

                // Level badge
                VStack(spacing: 2) {
                    Text("LVL")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.mutedText)
                    Text("\(character.level)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.veilPurple)
                        .monospacedDigit()
                }
                .frame(minWidth: 36)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.mutedText)
            }
            .padding(12)
            .background(Color.spaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.borderSubtle, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

#Preview("Character Picker Sheet") {
    let sampleChars: [Character] = [
        Character(id: "1", name: "Kael Voss",   species: "Arion",   charClass: "Tidecaller",  level: 5,  experiencePoints: 6500,  currentHP: 38, maxHP: 42, ac: 16, forcePoints: 12, lastModified: Date()),
        Character(id: "2", name: "Zara Teth",   species: "Sylari",  charClass: "Warden",     level: 3,  experiencePoints: 2100,  currentHP: 22, maxHP: 28, ac: 14, forcePoints: 6,  lastModified: Date()),
        Character(id: "3", name: "Brom Skalos", species: "Zabrak",  charClass: "Fabricant",  level: 7,  experiencePoints: 23000, currentHP: 55, maxHP: 55, ac: 17, forcePoints: 0,  lastModified: Date()),
    ]
    CharacterPickerSheet(
        characters: sampleChars,
        onSelect: { _ in },
        onCreateNew: {},
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
