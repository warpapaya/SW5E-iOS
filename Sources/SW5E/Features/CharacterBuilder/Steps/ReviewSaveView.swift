import SwiftUI

// MARK: - Step 8: Review & Save

struct ReviewSaveView: View {
    @ObservedObject var vm: CharacterBuilderViewModel
    var onCreated: ((String) -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Review Character")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.lightText)
                    Text("Confirm your choices before creating your character.")
                        .font(.subheadline)
                        .foregroundStyle(Color.mutedText)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Character summary card
                CharacterSummaryCard(draft: vm.draft)
                    .padding(.horizontal, 16)

                // Ability scores summary
                AbilityScoresSummarySection(scores: vm.draft.abilityScores)
                    .padding(.horizontal, 16)

                // Powers summary (if applicable)
                if !vm.draft.selectedPowers.isEmpty {
                    PowersSummarySection(powers: vm.draft.selectedPowers)
                        .padding(.horizontal, 16)
                }

                // Equipment summary
                if !vm.draft.selectedEquipment.isEmpty {
                    EquipmentSummarySection(
                        equipment: vm.draft.selectedEquipment.filter { $0.isSelected }
                    )
                    .padding(.horizontal, 16)
                }

                // Backstory preview
                if !vm.draft.backstory.isEmpty {
                    BackstorySummarySection(backstory: vm.draft.backstory)
                        .padding(.horizontal, 16)
                }

                // Validation warning
                if !vm.draft.isReadyToSave {
                    ReviewWarningBanner()
                        .padding(.horizontal, 16)
                }

                // Create Character button
                Button {
                    Task {
                        let success = await vm.createCharacter()
                        if success, let id = vm.savedCharacterID {
                            onCreated?(id)
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        if vm.isSaving {
                            ProgressView()
                                .tint(Color.spacePrimary)
                            Text("Creating Character…")
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.body.weight(.semibold))
                            Text("Create Character")
                        }
                    }
                    .font(.body.weight(.bold))
                    .foregroundStyle(vm.draft.isReadyToSave ? Color.spacePrimary : Color.mutedText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        vm.draft.isReadyToSave
                        ? LinearGradient(
                            colors: [.hologramBlue, .saberGreen.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                          )
                        : LinearGradient(
                            colors: [Color.borderSubtle, Color.borderSubtle],
                            startPoint: .leading,
                            endPoint: .trailing
                          )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: vm.draft.isReadyToSave ? Color.hologramBlue.opacity(0.35) : .clear, radius: 12, y: 4)
                }
                .disabled(!vm.draft.isReadyToSave || vm.isSaving)
                .padding(.horizontal, 16)
                .animation(.easeInOut(duration: 0.2), value: vm.draft.isReadyToSave)

                Spacer(minLength: 30)
            }
        }
        .background(Color.spacePrimary)
    }
}

// MARK: - Character Summary Card

private struct CharacterSummaryCard: View {
    let draft: CharacterDraft

    var gradient: [Color] {
        draft.charClass?.gradientColors ?? [.hologramBlue, .holoBlueSubtle]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header gradient band
            ZStack {
                LinearGradient(
                    colors: gradient.map { $0.opacity(0.5) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 90)

                HStack(spacing: 16) {
                    // Class icon avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 64, height: 64)
                        Image(systemName: draft.charClass?.classIcon ?? "person.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(draft.name.isEmpty ? "Unnamed Character" : draft.name)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.lightText)

                        HStack(spacing: 6) {
                            if let species = draft.species {
                                Text(species.name)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.hologramBlue)
                            }
                            if draft.species != nil && draft.charClass != nil {
                                Text("·").foregroundStyle(Color.mutedText)
                            }
                            if let cls = draft.charClass {
                                Text(cls.name)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.lightText)
                            }
                        }

                        if let bg = draft.background {
                            Text(bg.name)
                                .font(.caption)
                                .foregroundStyle(Color.mutedText)
                        }
                    }

                    Spacer()

                    // Level 1 badge
                    VStack(spacing: 2) {
                        Text("LVL")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.mutedText)
                        Text("1")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.lightText)
                    }
                }
                .padding(.horizontal, 16)
            }
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14))

            // Details row
            HStack(spacing: 0) {
                ReviewInfoCell(label: "Hit Die", value: draft.charClass.map { "d\(String($0.hitDie))" } ?? "—", color: .techOrange)
                Divider().frame(height: 40).background(Color.borderSubtle)
                ReviewInfoCell(label: "Primary", value: draft.charClass?.primaryStat.rawValue ?? "—", color: .hologramBlue)
                Divider().frame(height: 40).background(Color.borderSubtle)
                ReviewInfoCell(label: "Skills", value: draft.background.map { "\($0.skillGrants.count)" } ?? "0", color: .saberGreen)
                Divider().frame(height: 40).background(Color.borderSubtle)
                ReviewInfoCell(label: "Powers", value: "\(draft.selectedPowers.count)", color: Color(red: 0.49, green: 0.23, blue: 0.93))
            }
            .padding(.vertical, 10)
            .background(Color.spaceCard)
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 14, bottomTrailingRadius: 14))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.borderSubtle, lineWidth: 1)
        )
        .shadow(color: (gradient.first ?? Color.hologramBlue).opacity(0.2), radius: 12, y: 4)
    }
}

private struct ReviewInfoCell: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.headline.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.mutedText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Ability Scores Summary

private struct AbilityScoresSummarySection: View {
    let scores: AbilityScores

    var body: some View {
        ReviewSection(title: "Ability Scores", icon: "chart.bar.fill", color: .hologramBlue) {
            HStack(spacing: 0) {
                ForEach(AbilityStat.allCases, id: \.self) { stat in
                    let val = scores.value(for: stat)
                    let mod = scores.modifier(for: val)
                    VStack(spacing: 3) {
                        Text(stat.rawValue)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.mutedText)
                        Text("\(val)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.lightText)
                        Text(mod >= 0 ? "+\(mod)" : "\(mod)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(mod >= 0 ? Color.saberGreen : Color.siithRed)
                    }
                    .frame(maxWidth: .infinity)
                    if stat != .charisma {
                        Divider().background(Color.borderSubtle).frame(height: 36)
                    }
                }
            }
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Powers Summary

private struct PowersSummarySection: View {
    let powers: [CBPower]

    var body: some View {
        ReviewSection(title: "Selected Powers", icon: "sparkles", color: Color(red: 0.49, green: 0.23, blue: 0.93)) {
            ForEach(powers) { power in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(power.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.lightText)
                        Text(power.isCantrip ? "At-will" : "1st level · \(power.cost)")
                            .font(.caption)
                            .foregroundStyle(Color.mutedText)
                    }
                    Spacer()
                    Text(power.type.capitalized)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(power.type == "force"
                            ? Color(red: 0.49, green: 0.23, blue: 0.93)
                            : Color.techOrange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((power.type == "force"
                            ? Color(red: 0.49, green: 0.23, blue: 0.93)
                            : Color.techOrange).opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                if power.id != powers.last?.id {
                    Divider().background(Color.borderSubtle)
                }
            }
        }
    }
}

// MARK: - Equipment Summary

private struct EquipmentSummarySection: View {
    let equipment: [CBEquipment]

    var body: some View {
        ReviewSection(title: "Starting Equipment", icon: "backpack.fill", color: .techOrange) {
            ForEach(equipment) { item in
                HStack {
                    Image(systemName: item.typeIcon)
                        .foregroundStyle(Color.techOrange)
                        .frame(width: 20)
                    Text(item.name)
                        .font(.subheadline)
                        .foregroundStyle(Color.lightText)
                    Spacer()
                    Text(item.encumbranceLabel)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.mutedText)
                }
                if item.id != equipment.last?.id {
                    Divider().background(Color.borderSubtle)
                }
            }
        }
    }
}

// MARK: - Backstory Summary

private struct BackstorySummarySection: View {
    let backstory: String

    var body: some View {
        ReviewSection(title: "Backstory", icon: "text.book.closed.fill", color: .mutedText) {
            Text(backstory)
                .font(.subheadline)
                .foregroundStyle(Color.lightText)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(5)
        }
    }
}

// MARK: - Warning Banner

private struct ReviewWarningBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.techOrange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Missing required fields")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.techOrange)
                Text("Make sure you have a name, species, class, and background.")
                    .font(.caption)
                    .foregroundStyle(Color.mutedText)
            }
        }
        .padding(12)
        .background(Color.techOrange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.techOrange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Reusable Review Section

private struct ReviewSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding(12)
            .background(Color.spaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.borderSubtle, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview("Review & Save") {
    var draft = CharacterDraft()
    draft.name = "Kira Voss"
    draft.species = CBSpecies.samples.first
    draft.charClass = CBClass.samples.first
    draft.background = CBBackground.samples.first
    draft.selectedPowers = [CBPower.forceSamples[0], CBPower.forceSamples[3]]
    draft.selectedEquipment = CBEquipment.samples(forClass: "Tidecaller")
    draft.backstory = "Once a Tidecaller initiate, Kira left the Order after the fall of the old guard. Now she wanders the outer systems, using her Veil training to protect those who cannot protect themselves."

    let vm = CharacterBuilderViewModel()
    vm.draft = draft

    return ReviewSaveView(vm: vm)
        .preferredColorScheme(.dark)
        .background(Color.spacePrimary)
}
