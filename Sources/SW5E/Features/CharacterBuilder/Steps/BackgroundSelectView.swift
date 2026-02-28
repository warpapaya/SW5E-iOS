import SwiftUI

// MARK: - Step 3: Background Selection

struct BackgroundSelectView: View {
    @ObservedObject var vm: CharacterBuilderViewModel
    @State private var expandedID: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Choose Your Background")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.lightText)
                    Text("Your background grants skill proficiencies and a special feature.")
                        .font(.subheadline)
                        .foregroundStyle(Color.mutedText)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                if vm.isLoading {
                    ProgressView("Loading backgrounds…")
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .tint(Color.hologramBlue)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(vm.availableBackgrounds) { bg in
                            BackgroundCard(
                                background: bg,
                                isSelected: vm.draft.background?.id == bg.id,
                                isExpanded: expandedID == bg.id
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    if expandedID == bg.id {
                                        vm.select(background: bg)
                                    } else {
                                        expandedID = bg.id
                                    }
                                }
                            }
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

// MARK: - Background Card

private struct BackgroundCard: View {
    let background: CBBackground
    let isSelected: Bool
    let isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Collapsed / header row
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.hologramBlue.opacity(0.2) : Color.borderSubtle.opacity(0.5))
                        .frame(width: 44, height: 44)
                    Image(systemName: "book.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? Color.hologramBlue : Color.mutedText)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(background.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(isSelected ? Color.hologramBlue : Color.lightText)

                    // Skill grants
                    HStack(spacing: 6) {
                        ForEach(background.skillGrants, id: \.self) { skill in
                            Text(skill)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Color.saberGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.saberGreen.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }

                Spacer()

                // Checkmark or chevron
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.saberGreen)
                } else {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.mutedText)
                }
            }
            .padding(14)

            // Expanded detail
            if isExpanded {
                Divider()
                    .background(Color.borderSubtle)

                VStack(alignment: .leading, spacing: 10) {
                    // Feature section
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Background Feature", systemImage: "sparkles")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.techOrange)

                        Text(background.featureDescription)
                            .font(.subheadline)
                            .foregroundStyle(Color.lightText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Skill proficiencies detail
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Skill Proficiencies", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.hologramBlue)

                        HStack(spacing: 8) {
                            ForEach(background.skillGrants, id: \.self) { skill in
                                HStack(spacing: 4) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6))
                                        .foregroundStyle(Color.hologramBlue)
                                    Text(skill)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.lightText)
                                }
                            }
                        }
                    }

                    // Select CTA
                    Button {
                        // Handled by outer tap
                    } label: {
                        Text(isSelected ? "✓ Selected" : "Select \(background.name)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isSelected ? Color.saberGreen : Color.spacePrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background {
                                if isSelected {
                                    Color.saberGreen.opacity(0.2)
                                } else {
                                    LinearGradient(
                                        colors: [.hologramBlue, .saberGreen.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(true) // parent tap gesture handles selection
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .padding(.top, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.spaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isSelected ? Color.saberGreen : (isExpanded ? Color.hologramBlue.opacity(0.5) : Color.borderSubtle),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(color: isSelected ? Color.saberGreen.opacity(0.15) : .clear, radius: 8)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }
}

// MARK: - Preview

#Preview("Background Select") {
    let vm = CharacterBuilderViewModel()
    vm.availableBackgrounds = CBBackground.samples
    return BackgroundSelectView(vm: vm)
        .preferredColorScheme(.dark)
        .background(Color.spacePrimary)
}
