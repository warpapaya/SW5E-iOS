import SwiftUI

// MARK: - Step 1: Species Selection

struct SpeciesSelectView: View {
    @ObservedObject var vm: CharacterBuilderViewModel
    @State private var selectedForDetail: CBSpecies? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Section header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Choose Your Species")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.lightText)
                    Text("Your species shapes your natural abilities and traits.")
                        .font(.subheadline)
                        .foregroundStyle(Color.mutedText)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                if vm.isLoading {
                    ProgressView("Loading species…")
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .tint(Color.veilGold)
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(vm.availableSpecies) { species in
                            SpeciesCard(
                                species: species,
                                isSelected: vm.draft.species?.id == species.id
                            )
                            .onTapGesture {
                                selectedForDetail = species
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                }

                Spacer(minLength: 20)
            }
        }
        .background(Color.spacePrimary)
        .sheet(item: $selectedForDetail) { species in
            SpeciesDetailSheet(species: species, isSelected: vm.draft.species?.id == species.id) {
                vm.select(species: species)
                selectedForDetail = nil
            }
        }
    }
}

// MARK: - Species Card

private struct SpeciesCard: View {
    let species: CBSpecies
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            // Portrait — full bleed, square crop
            Image(species.imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fill)
                .clipped()

            // Name scrim + label
            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 60)

            Text(species.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.bottom, 10)
                .padding(.horizontal, 8)
                .lineLimit(1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isSelected ? Color.veilGold : Color.borderSubtle.opacity(0.5),
                    lineWidth: isSelected ? 2.5 : 1
                )
        )
        .shadow(color: isSelected ? Color.veilGold.opacity(0.35) : .clear, radius: 10)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .accessibilityLabel("\(species.name)\(isSelected ? ", selected" : "")")
        .accessibilityHint("Tap to view details")
    }
}

// MARK: - Species Detail Sheet

private struct SpeciesDetailSheet: View {
    let species: CBSpecies
    let isSelected: Bool
    let onSelect: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hero portrait
                    Image(species.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [.clear, Color.spacePrimary],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                        )

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                            .foregroundStyle(Color.veilGold)
                        Text(species.description)
                            .font(.body)
                            .foregroundStyle(Color.lightText)
                    }
                    .padding(.horizontal, 20)

                    // Ability Bonuses
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ability Bonuses")
                            .font(.headline)
                            .foregroundStyle(Color.veilGold)
                        HStack(spacing: 10) {
                            ForEach(Array(species.abilityBonuses), id: \.key) { key, val in
                                VStack(spacing: 2) {
                                    Text("+\(val)")
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(Color.veilGlow)
                                    Text(key.uppercased())
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.mutedText)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.spaceCard)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(Color.veilGlow.opacity(0.4), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Traits
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Species Traits")
                            .font(.headline)
                            .foregroundStyle(Color.veilGold)
                        ForEach(species.traits, id: \.self) { trait in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.veilGold)
                                    .padding(.top, 2)
                                Text(trait)
                                    .font(.body)
                                    .foregroundStyle(Color.lightText)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Select button
                    Button(action: {
                        onSelect()
                        dismiss()
                    }) {
                        Text(isSelected ? "✓ Selected" : "Select \(species.name)")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(isSelected ? Color.veilGlow : Color.spacePrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background {
                                if isSelected {
                                    Color.veilGlow.opacity(0.2)
                                } else {
                                    LinearGradient(colors: [.veilGold, .veilGlow.opacity(0.8)],
                                                   startPoint: .leading, endPoint: .trailing)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 14).strokeBorder(Color.veilGlow, lineWidth: 1)
                                }
                            }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .padding(.top, 16)
            }
            .background(Color.spacePrimary.ignoresSafeArea())
            .navigationTitle(species.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.veilGold)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Species Select") {
    let vm = CharacterBuilderViewModel()
    vm.availableSpecies = CBSpecies.samples
    return SpeciesSelectView(vm: vm)
        .preferredColorScheme(.dark)
        .background(Color.spacePrimary)
}
