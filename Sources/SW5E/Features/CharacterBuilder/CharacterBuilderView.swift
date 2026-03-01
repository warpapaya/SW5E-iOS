import SwiftUI

// MARK: - Character Builder View (Root Container)

struct CharacterBuilderView: View {
    @StateObject private var vm = CharacterBuilderViewModel()
    @Environment(\.dismiss) private var dismiss

    // Callback when character is successfully created
    var onCreated: ((String) -> Void)? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.spacePrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Progress Dots
                    progressHeader

                    // MARK: - Step Content
                    stepContent
                        .transition(.asymmetric(
                            insertion:  .move(edge: .trailing).combined(with: .opacity),
                            removal:    .move(edge: .leading).combined(with: .opacity)
                        ))
                        .id(vm.currentStep)

                    // MARK: - Navigation Buttons
                    navigationFooter
                }
            }
            .navigationTitle(vm.currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.mutedText)
                }
            }
        }
        .task { await vm.loadInitialData() }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 8) {
            // Step label
            Text("Step \(vm.currentVisibleIndex + 1) of \(vm.totalVisibleSteps)")
                .font(.caption)
                .foregroundStyle(Color.mutedText)

            // Dot indicators
            HStack(spacing: 6) {
                ForEach(0..<vm.totalVisibleSteps, id: \.self) { index in
                    let isActive    = index == vm.currentVisibleIndex
                    let isCompleted = index < vm.currentVisibleIndex
                    Circle()
                        .fill(isActive    ? Color.veilGold :
                              isCompleted ? Color.veilGlow   : Color.borderSubtle)
                        .frame(width: isActive ? 10 : 7, height: isActive ? 10 : 7)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: vm.currentStep)
                        .overlay(
                            isCompleted
                            ? Circle().strokeBorder(Color.veilGlow.opacity(0.5), lineWidth: 1)
                            : nil
                        )
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.borderSubtle)
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [.veilGold, .veilGlow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * (CGFloat(vm.currentVisibleIndex + 1) / CGFloat(vm.totalVisibleSteps)),
                            height: 3
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.currentStep)
                }
            }
            .frame(height: 3)
            .padding(.horizontal)
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.spaceCard.opacity(0.8))
    }

    // MARK: - Step Content Router

    @ViewBuilder
    private var stepContent: some View {
        switch vm.currentStep {
        case .species:
            SpeciesSelectView(vm: vm)
        case .charClass:
            ClassSelectView(vm: vm)
        case .background:
            BackgroundSelectView(vm: vm)
        case .ability:
            AbilityScoresView(vm: vm)
        case .powers:
            PowersSelectView(vm: vm)
        case .equipment:
            EquipmentSelectView(vm: vm)
        case .details:
            DetailsFormView(vm: vm)
        case .review:
            ReviewSaveView(vm: vm, onCreated: { id in
                onCreated?(id)
                dismiss()
            })
        }
    }

    // MARK: - Navigation Footer

    private var navigationFooter: some View {
        HStack(spacing: 16) {
            // Back button
            if vm.canGoBack {
                Button(action: vm.goBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.lightText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.spaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.borderSubtle, lineWidth: 1)
                    )
                }
                .frame(maxWidth: 120)
            }

            // Next / Finish button (hidden on review step — ReviewSaveView has its own CTA)
            if vm.currentStep != .review {
                Button(action: vm.goNext) {
                    HStack(spacing: 6) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(vm.canProceed ? Color.spacePrimary : Color.mutedText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        vm.canProceed
                        ? LinearGradient(colors: [.veilGold, .veilGlow.opacity(0.8)],
                                         startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.borderSubtle, Color.borderSubtle],
                                         startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!vm.canProceed)
                .animation(.easeInOut(duration: 0.2), value: vm.canProceed)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Color.spaceCard
                .shadow(color: .black.opacity(0.4), radius: 8, y: -4)
        )
    }
}

// MARK: - Preview

#Preview("Character Builder") {
    CharacterBuilderView()
        .preferredColorScheme(.dark)
}
