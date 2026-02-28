import SwiftUI

/// Demo view showcasing dice rolling with animations, haptics, and micro-interactions.
struct DiceRollDemo: View {

    @State private var selectedSides: Int = 20
    @State private var modifier: Int = 4
    @State private var rollCount: Int = 1
    @State private var useAdvantage: Bool = false
    @State private var useDisadvantage: Bool = false
    @State private var diceResult: DiceResult?
    @State private var showOverlay: Bool = false
    @State private var selectedModifierType: String = ""

    private let roller = DiceRollerService()

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                if let result = diceResult, !showOverlay {
                    DiceResultCard(result: result)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .scale),
                            removal:   .move(edge: .leading).combined(with: .scale)
                        ))
                }

                Spacer()

                DiceRollControls(
                    sides: $selectedSides,
                    modifier: $modifier,
                    rollCount: $rollCount,
                    advantage: $useAdvantage,
                    disadvantage: $useDisadvantage,
                    modifierType: $selectedModifierType,
                    onRoll: performRoll
                )

                Spacer()
            }
            .navigationTitle("Dice Roller Demo")
            .sheet(isPresented: $showOverlay) {
                if let result = diceResult {
                    DiceRollOverlay(
                        sides: selectedSides,
                        rolls: result.rolls,
                        modifier: result.modifier,
                        total: result.total
                    )
                }
            }
        }
    }

    private func performRoll() {
        HapticsManager.shared.heavyAction()
        Task {
            let result = await roller.rollDice(
                count: rollCount,
                sides: selectedSides,
                modifier: modifier,
                advantage: useAdvantage,
                disadvantage: useDisadvantage
            )
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    diceResult = result
                    if selectedSides == 20 && rollCount == 1 {
                        showOverlay = true
                    } else {
                        HapticsManager.shared.uiInteraction()
                    }
                }
            }
        }
    }
}

// MARK: - Result Card

struct DiceResultCard: View {
    let result: DiceResult

    @State private var showAnimation = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Roll Result")
                .font(.subheadline)
                .foregroundStyle(Color.mutedText)

            HStack(spacing: 8) {
                ForEach(result.rolls, id: \.self) { roll in
                    Text("\(roll)")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(colorForRoll(roll))
                        .scaleEffect(showAnimation ? 1.0 : 0.5)
                }
            }

            HStack(spacing: 4) {
                Text("+")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.hologramBlue)
                Text("\(result.modifier)")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(result.modifier >= 0 ? Color.saberGreen : Color.siithRed)
            }

            Text("= \(result.total)")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundStyle(colorForTotal())
        }
        .padding()
        .background(Color.spaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(colorForTotal(), lineWidth: 2)
        )
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showAnimation = true
            }
        }
    }

    private func colorForRoll(_ roll: Int) -> Color {
        if result.isCrit { return .techOrange }
        if result.isFail && roll == 1 { return .siithRed }
        if result.total >= 15 { return .hologramBlue }
        if result.total <= 8 { return .techOrange }
        return .lightText
    }

    private func colorForTotal() -> Color {
        if result.isCrit { return .techOrange }
        if result.isFail { return .siithRed }
        if result.total >= 15 { return .hologramBlue }
        if result.total <= 8 { return .techOrange }
        return .lightText
    }
}

// MARK: - Controls

struct DiceRollControls: View {
    @Binding var sides: Int
    @Binding var modifier: Int
    @Binding var rollCount: Int
    @Binding var advantage: Bool
    @Binding var disadvantage: Bool
    @Binding var modifierType: String
    let onRoll: () -> Void

    let availableTypes = ["", "DEX", "CON", "INT", "WIS", "CHA", "STR"]

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Die Type")
                    .font(.subheadline)
                    .foregroundStyle(Color.lightText)
                Spacer()
                Picker("", selection: $sides) {
                    ForEach([4, 6, 8, 10, 12, 20, 100], id: \.self) { s in
                        Text("d\(s)").tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            HStack {
                Text("Modifier")
                    .font(.subheadline)
                    .foregroundStyle(Color.lightText)
                Spacer()
                Stepper("\(modifier)", value: $modifier, in: -10...20)
                    .labelsHidden()
            }

            HStack {
                Text("Attribute")
                    .font(.subheadline)
                    .foregroundStyle(Color.lightText)
                Spacer()
                Picker("", selection: $modifierType) {
                    ForEach(availableTypes, id: \.self) { type in
                        Text(type.isEmpty ? "None" : type).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Rolls")
                        .font(.subheadline)
                        .foregroundStyle(Color.lightText)
                    Stepper("\(rollCount)", value: $rollCount, in: 1...5)
                        .labelsHidden()
                }
                Spacer()
                VStack(spacing: 8) {
                    Toggle("Adv", isOn: $advantage)
                    Toggle("Dis", isOn: $disadvantage)
                }
            }

            Button(action: {
                HapticsManager.shared.buttonTap()
                onRoll()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "die.face.6")
                        .font(.title2)
                    Text("ROLL \(sides == 100 ? "d100" : "d\(sides)")")
                        .font(.headline)
                }
                .foregroundStyle(Color.spacePrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.hologramBlue)
                .cornerRadius(12)
            }
        }
        .padding()
        .holoCard()
    }
}

// MARK: - Preview

#Preview("Dice Roll Demo") {
    DiceRollDemo()
        .preferredColorScheme(.dark)
}
