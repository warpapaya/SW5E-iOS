import SwiftUI

// MARK: - Step 4: Ability Scores (Point Buy)

struct AbilityScoresView: View {
    @ObservedObject var vm: CharacterBuilderViewModel

    private let stats = AbilityStat.allCases
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header + points remaining
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assign Ability Scores")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.lightText)
                    Text("Point-buy system: distribute 27 points. Base 8, max 15 before racial bonuses.")
                        .font(.subheadline)
                        .foregroundStyle(Color.mutedText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Points remaining banner
                PointsRemainingBanner(remaining: vm.draft.abilityScores.pointsRemaining)
                    .padding(.horizontal, 16)

                // Stat grid
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(stats, id: \.self) { stat in
                        AbilityStatControl(
                            stat: stat,
                            scores: $vm.draft.abilityScores,
                            isPrimary: vm.draft.charClass?.primaryStat == stat
                        )
                    }
                }
                .padding(.horizontal, 16)

                // Stat block summary
                StatBlockSummaryView(scores: vm.draft.abilityScores)
                    .padding(.horizontal, 16)

                // Racial bonus note
                if let species = vm.draft.species, !species.abilityBonuses.isEmpty {
                    RacialBonusNoteView(species: species)
                        .padding(.horizontal, 16)
                }

                Spacer(minLength: 20)
            }
        }
        .background(Color.spacePrimary)
    }
}

// MARK: - Points Remaining Banner

private struct PointsRemainingBanner: View {
    let remaining: Int

    var bannerColor: Color {
        if remaining < 0  { return .voidRed }
        if remaining <= 5 { return .veilPurple }
        return .veilGold
    }

    var body: some View {
        HStack {
            Image(systemName: remaining < 0 ? "exclamationmark.triangle.fill" : "sparkles")
                .font(.title3)
                .foregroundStyle(bannerColor)

            Text("\(remaining) points remaining")
                .font(.headline.weight(.semibold))
                .foregroundStyle(bannerColor)

            Spacer()

            // Mini progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.borderSubtle)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(bannerColor)
                        .frame(
                            width: max(0, geo.size.width * CGFloat(AbilityScores.maxPoints - remaining) / CGFloat(AbilityScores.maxPoints)),
                            height: 8
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: remaining)
                }
            }
            .frame(width: 100, height: 8)
        }
        .padding(14)
        .background(bannerColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(bannerColor.opacity(0.3), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: remaining)
    }
}

// MARK: - Ability Stat Control (single stat card with +/-)

private struct AbilityStatControl: View {
    let stat: AbilityStat
    @Binding var scores: AbilityScores
    let isPrimary: Bool

    private var score: Int { scores.value(for: stat) }
    private var modifier: Int { scores.modifier(for: score) }
    private var modString: String { modifier >= 0 ? "+\(modifier)" : "\(modifier)" }
    private var cost: Int { AbilityScores.pointCost[score] ?? 0 }

    var body: some View {
        VStack(spacing: 8) {
            // Stat label
            HStack(spacing: 3) {
                Text(stat.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isPrimary ? Color.veilPurple : Color.mutedText)
                if isPrimary {
                    Image(systemName: "star.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(Color.veilPurple)
                }
            }

            // Score display
            Text("\(score)")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(isPrimary ? Color.veilPurple : Color.lightText)
                .animation(.spring(response: 0.2), value: score)

            // Modifier
            Text(modString)
                .font(.caption.weight(.semibold))
                .foregroundStyle(modifier >= 0 ? Color.veilGlow : Color.voidRed)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background((modifier >= 0 ? Color.veilGlow : Color.voidRed).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 5))

            // +/- buttons
            HStack(spacing: 0) {
                Button {
                    scores.decrease(stat)
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    Image(systemName: "minus")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(score > 8 ? Color.lightText : Color.borderSubtle)
                        .frame(maxWidth: .infinity, minHeight: 28)
                }
                .disabled(score <= 8)

                Divider()
                    .frame(height: 20)
                    .background(Color.borderSubtle)

                Button {
                    scores.increase(stat)
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(canIncrease ? Color.lightText : Color.borderSubtle)
                        .frame(maxWidth: .infinity, minHeight: 28)
                }
                .disabled(!canIncrease)
            }
            .background(Color.borderSubtle.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 7))

            // Point cost label
            Text("Cost: \(cost) pts")
                .font(.system(size: 9).weight(.medium))
                .foregroundStyle(Color.mutedText)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.spaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isPrimary ? Color.veilPurple.opacity(0.5) : Color.borderSubtle,
                            lineWidth: isPrimary ? 1.5 : 1
                        )
                )
                .shadow(color: isPrimary ? Color.veilPurple.opacity(0.1) : .clear, radius: 6)
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: score)
    }

    private var canIncrease: Bool {
        score < 15
        && (AbilityScores.pointCost[score + 1].map { $0 - (AbilityScores.pointCost[score] ?? 0) } ?? 99) <= scores.pointsRemaining
    }
}

// MARK: - Stat Block Summary

private struct StatBlockSummaryView: View {
    let scores: AbilityScores

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Stat Block Preview")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.mutedText)

            HStack(spacing: 0) {
                ForEach(AbilityStat.allCases, id: \.self) { stat in
                    let val = scores.value(for: stat)
                    let mod = scores.modifier(for: val)
                    VStack(spacing: 4) {
                        Text(stat.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.mutedText)
                        Text("\(val)")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.lightText)
                        Text(mod >= 0 ? "+\(mod)" : "\(mod)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(mod >= 0 ? Color.veilGlow : Color.voidRed)
                    }
                    .frame(maxWidth: .infinity)
                    if stat != .charisma {
                        Divider().background(Color.borderSubtle)
                    }
                }
            }
            .padding(.vertical, 12)
            .background(Color.spaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.borderSubtle, lineWidth: 1)
            )
        }
    }
}

// MARK: - Racial Bonus Note

private struct RacialBonusNoteView: View {
    let species: CBSpecies

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color.veilGold)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(species.name) Racial Bonuses (applied at save)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.veilGold)

                HStack(spacing: 8) {
                    ForEach(Array(species.abilityBonuses), id: \.key) { key, val in
                        Text("+\(val) \(key.uppercased())")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.veilGlow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.veilGlow.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
        }
        .padding(12)
        .background(Color.veilGold.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.veilGold.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Ability Scores") {
    let vm = CharacterBuilderViewModel()
    vm.draft.charClass = CBClass.samples.first
    vm.draft.species = CBSpecies.samples.first
    return AbilityScoresView(vm: vm)
        .preferredColorScheme(.dark)
        .background(Color.spacePrimary)
}
