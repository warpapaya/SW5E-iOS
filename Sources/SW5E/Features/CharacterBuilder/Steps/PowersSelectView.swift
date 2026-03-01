import SwiftUI

// MARK: - Step 5: Powers Selection (Force / Tech casters only)

struct PowersSelectView: View {
    @ObservedObject var vm: CharacterBuilderViewModel

    private var isForce: Bool { vm.draft.charClass?.isForceUser ?? false }
    private var powerLabel: String { isForce ? "Force" : "Tech" }
    private var powers: [CBPower] { vm.availablePowers }

    private var cantrips: [CBPower] { powers.filter { $0.isCantrip } }
    private var level1Powers: [CBPower] { powers.filter { $0.level == 1 } }

    // Limits
    private let cantripLimit = 3
    private let level1Limit  = 2

    private var selectedCantrips:     [CBPower] { vm.draft.selectedPowers.filter { $0.isCantrip } }
    private var selectedLevel1Powers: [CBPower] { vm.draft.selectedPowers.filter { $0.level == 1 } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Choose \(powerLabel) Powers")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.lightText)
                    Text("Select up to \(cantripLimit) at-will powers and \(level1Limit) 1st-level powers.")
                        .font(.subheadline)
                        .foregroundStyle(Color.mutedText)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                if vm.isLoading {
                    ProgressView("Loading powers…")
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .tint(isForce ? Color(red: 0.49, green: 0.23, blue: 0.93) : Color.veilPurple)
                } else {
                    // At-will / Cantrip section
                    PowerSectionView(
                        title: "At-Will Powers",
                        subtitle: "\(selectedCantrips.count)/\(cantripLimit) selected",
                        icon: "infinity.circle.fill",
                        accentColor: isForce ? Color(red: 0.49, green: 0.23, blue: 0.93) : Color.veilPurple,
                        powers: cantrips,
                        selectedPowers: vm.draft.selectedPowers,
                        isAtLimit: selectedCantrips.count >= cantripLimit,
                        onToggle: { power in
                            if vm.isPowerSelected(power) || selectedCantrips.count < cantripLimit {
                                vm.togglePower(power)
                            }
                        }
                    )
                    .padding(.horizontal, 16)

                    // 1st level section
                    PowerSectionView(
                        title: "1st-Level Powers",
                        subtitle: "\(selectedLevel1Powers.count)/\(level1Limit) selected",
                        icon: "1.circle.fill",
                        accentColor: isForce ? Color.veilGold : Color.veilGlow,
                        powers: level1Powers,
                        selectedPowers: vm.draft.selectedPowers,
                        isAtLimit: selectedLevel1Powers.count >= level1Limit,
                        onToggle: { power in
                            if vm.isPowerSelected(power) || selectedLevel1Powers.count < level1Limit {
                                vm.togglePower(power)
                            }
                        }
                    )
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 20)
            }
        }
        .background(Color.spacePrimary)
        .task { await vm.availablePowers.isEmpty ? loadPowersIfNeeded() : () }
    }

    private func loadPowersIfNeeded() async {
        // Powers are loaded by the VM when navigating to this step
    }
}

// MARK: - Power Section

private struct PowerSectionView: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let powers: [CBPower]
    let selectedPowers: [CBPower]
    let isAtLimit: Bool
    let onToggle: (CBPower) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(accentColor)

                Spacer()

                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accentColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if powers.isEmpty {
                Text("No powers available")
                    .font(.subheadline)
                    .foregroundStyle(Color.mutedText)
                    .padding(.vertical, 10)
            } else {
                ForEach(powers) { power in
                    let isSelected = selectedPowers.contains(power)
                    let isDisabled = !isSelected && isAtLimit

                    PowerRow(
                        power: power,
                        isSelected: isSelected,
                        isDisabled: isDisabled,
                        accentColor: accentColor
                    )
                    .onTapGesture { onToggle(power) }
                    .opacity(isDisabled ? 0.45 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
                }
            }
        }
    }
}

// MARK: - Power Row

private struct PowerRow: View {
    let power: CBPower
    let isSelected: Bool
    let isDisabled: Bool
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? accentColor.opacity(0.2) : Color.borderSubtle.opacity(0.4))
                    .frame(width: 28, height: 28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(isSelected ? accentColor : Color.borderSubtle, lineWidth: 1.5)
                    )
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(accentColor)
                }
            }

            // Power info
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(power.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? accentColor : Color.lightText)

                    Spacer()

                    Text(power.cost)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.veilPurple)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.veilPurple.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                HStack(spacing: 8) {
                    Label(power.duration, systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(Color.mutedText)

                    Text("·")
                        .foregroundStyle(Color.mutedText)

                    Text(power.description)
                        .font(.caption2)
                        .foregroundStyle(Color.mutedText)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.spaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isSelected ? accentColor : Color.borderSubtle,
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
                .shadow(color: isSelected ? accentColor.opacity(0.15) : .clear, radius: 6)
        )
    }
}

// MARK: - Preview

#Preview("Powers Select — Veil") {
    let vm = CharacterBuilderViewModel()
    vm.draft.charClass = CBClass.samples.first(where: { $0.isForceUser })
    vm.availablePowers = CBPower.forceSamples
    return PowersSelectView(vm: vm)
        .preferredColorScheme(.dark)
        .background(Color.spacePrimary)
}

#Preview("Powers Select — Tech") {
    let vm = CharacterBuilderViewModel()
    vm.draft.charClass = CBClass.samples.first(where: { $0.isTechUser })
    vm.availablePowers = CBPower.techSamples
    return PowersSelectView(vm: vm)
        .preferredColorScheme(.dark)
        .background(Color.spacePrimary)
}
