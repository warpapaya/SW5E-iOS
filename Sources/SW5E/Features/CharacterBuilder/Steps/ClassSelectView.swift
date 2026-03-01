import SwiftUI

// MARK: - Step 2: Class Selection

struct ClassSelectView: View {
    @ObservedObject var vm: CharacterBuilderViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Choose Your Class")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.lightText)
                    Text("Your class defines your combat style and special abilities.")
                        .font(.subheadline)
                        .foregroundStyle(Color.mutedText)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                if vm.isLoading {
                    ProgressView("Loading classes…")
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .tint(Color.hologramBlue)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(vm.availableClasses) { charClass in
                            ClassCard(
                                charClass: charClass,
                                isSelected: vm.draft.charClass?.id == charClass.id,
                                primaryStatOfDraft: vm.draft.charClass?.primaryStat
                            )
                            .onTapGesture { vm.select(charClass: charClass) }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 20)
            }
        }
        .background(Color.spacePrimary)
    }
}

// MARK: - Class Card

private struct ClassCard: View {
    let charClass: CBClass
    let isSelected: Bool
    let primaryStatOfDraft: AbilityStat?

    var body: some View {
        HStack(spacing: 0) {
            // Color bar accent
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: charClass.gradientColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 5)

            HStack(spacing: 14) {
                // Class icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: charClass.gradientColors.map { $0.opacity(0.3) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: charClass.classIcon)
                        .font(.system(size: 24))
                        .foregroundStyle(charClass.gradientColors.first ?? .hologramBlue)
                }

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(charClass.name)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.lightText)

                        Spacer()

                        // Hit die badge
                        Text("d\(charClass.hitDie)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.techOrange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.techOrange.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    // Tags row
                    HStack(spacing: 6) {
                        // Primary stat
                        ClassTagView(
                            label: charClass.primaryStat.rawValue,
                            color: .hologramBlue,
                            icon: "chart.bar.fill"
                        )

                        // Veil/Tech badge
                        if charClass.isForceUser {
                            ClassTagView(label: "Force", color: Color(red: 0.49, green: 0.23, blue: 0.93), icon: "sparkles")
                        } else if charClass.isTechUser {
                            ClassTagView(label: "Tech", color: .techOrange, icon: "cpu.fill")
                        }
                    }

                    // Role description
                    Text(charClass.roleDescription)
                        .font(.subheadline)
                        .foregroundStyle(Color.mutedText)
                        .lineLimit(2)
                }
                .padding(.vertical, 14)
                .padding(.trailing, 14)
            }
            .padding(.leading, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.spaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isSelected
                            ? (charClass.gradientColors.first ?? Color.hologramBlue)
                            : Color.borderSubtle,
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(
                    color: isSelected ? (charClass.gradientColors.first ?? Color.hologramBlue).opacity(0.25) : .clear,
                    radius: 10
                )
        )
        .scaleEffect(isSelected ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .accessibilityLabel("\(charClass.name), d\(charClass.hitDie) hit die, primary stat \(charClass.primaryStat.fullName). \(isSelected ? "Selected." : "")")
    }
}

// MARK: - Class Tag

private struct ClassTagView: View {
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

// MARK: - Preview

#Preview("Class Select") {
    let vm = CharacterBuilderViewModel()
    vm.availableClasses = CBClass.samples
    return ClassSelectView(vm: vm)
        .preferredColorScheme(.dark)
        .background(Color.spacePrimary)
}
