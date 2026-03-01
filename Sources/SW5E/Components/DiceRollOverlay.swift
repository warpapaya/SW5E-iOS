import SwiftUI

/// Fullscreen overlay showing animated dice roll results.
struct DiceRollOverlay: View {
    let sides: Int
    let rolls: [Int]
    let modifier: Int
    let total: Int

    @State private var showResult = false
    @Environment(\.dismiss) private var dismiss

    var isCrit: Bool { sides == 20 && rolls.contains(20) }
    var isFail: Bool { sides == 20 && rolls.contains(1) }

    var resultColor: Color {
        if isCrit { return .veilPurple }
        if isFail { return .voidRed }
        if total >= 15 { return .veilGold }
        return .veilPurple
    }

    var body: some View {
        GeometryReader { _ in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    if showResult {
                        Text("\(total)")
                            .font(.system(size: 96, weight: .bold, design: .monospaced))
                            .foregroundStyle(resultColor.gradient)
                            .shadow(color: resultColor.opacity(0.5), radius: isCrit ? 20 : 8)
                            .scaleEffect(showResult ? 1.0 : 0.5)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showResult)

                        Spacer().frame(height: 20)

                        VStack(spacing: 8) {
                            HStack(spacing: 4) {
                                ForEach(rolls, id: \.self) { roll in
                                    Text("\(roll)")
                                        .font(.system(size: 36, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(Color.lightText)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.spaceCard)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                if modifier != 0 {
                                    Text(modifier > 0 ? "+\(modifier)" : "\(modifier)")
                                        .font(.system(size: 36, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(Color.veilGold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.veilGoldSubtle)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                            Text("TOTAL")
                                .font(.dataReadout)
                                .foregroundStyle(Color.mutedText)
                        }

                        Spacer()
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: resultColor))
                            .scaleEffect(2.0)
                    }

                    Button(action: { dismiss() }) {
                        Text("Tap to close")
                            .font(.dataReadout)
                            .foregroundStyle(Color.mutedText)
                            .padding(16)
                            .background(Color.spaceCard.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.8)) { showResult = true }
            }
        }
        .onTapGesture {
            withAnimation(.easeIn(duration: 0.2)) { dismiss() }
        }
    }
}

// MARK: - Preview
#Preview("Dice Roll Overlay") {
    DiceRollOverlay(sides: 20, rolls: [18], modifier: 4, total: 22)
}
