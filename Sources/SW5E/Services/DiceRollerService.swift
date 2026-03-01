import Foundation
import SwiftUI

/// Result of a dice roll containing all relevant information
struct DiceResult: Codable {
    let rolls: [Int]
    let total: Int
    let modifier: Int
    let isCrit: Bool
    let isFail: Bool

    var breakdownString: String {
        if rolls.count == 1 {
            return "\(rolls[0]) + \(modifier) = \(total)"
        } else {
            let rollSum = rolls.reduce(0, +)
            return "\(rollSum) (+\(modifier)) = \(total)"
        }
    }
}

/// Service for performing dice rolls with various configurations.
actor DiceRollerService {

    func rollDice(
        count: Int = 1,
        sides: Int = 20,
        modifier: Int = 0,
        advantage: Bool = false,
        disadvantage: Bool = false
    ) -> DiceResult {
        var rolls: [Int] = []

        for _ in 0..<count {
            if advantage {
                rolls.append(max(Int.random(in: 1...sides), Int.random(in: 1...sides)))
            } else if disadvantage {
                rolls.append(min(Int.random(in: 1...sides), Int.random(in: 1...sides)))
            } else {
                rolls.append(Int.random(in: 1...sides))
            }
        }

        let rawTotal = rolls.reduce(0, +)
        let isCrit = sides == 20 && rolls.contains { $0 == 20 }
        let isFail = sides == 20 && rolls.contains { $0 == 1 }

        return DiceResult(rolls: rolls, total: rawTotal + modifier, modifier: modifier, isCrit: isCrit, isFail: isFail)
    }

    func rollD20(modifier: Int = 0, advantage: Bool = false, disadvantage: Bool = false) -> DiceResult {
        rollDice(count: 1, sides: 20, modifier: modifier, advantage: advantage, disadvantage: disadvantage)
    }

    func rollDamage(diceConfig: [(count: Int, sides: Int)], modifier: Int = 0) -> DiceResult {
        var rolls: [Int] = []
        for config in diceConfig {
            for _ in 0..<config.count {
                rolls.append(Int.random(in: 1...config.sides))
            }
        }
        let rawTotal = rolls.reduce(0, +)
        return DiceResult(rolls: rolls, total: rawTotal + modifier, modifier: modifier, isCrit: false, isFail: false)
    }
}

// MARK: - Preview

#Preview("Dice Roller Service") {
    VStack(spacing: 12) {
        Text("Dice Roller")
            .font(.holoDisplay)
            .foregroundColor(Color.veilGold)
        Text("Actor-based dice rolling service")
            .font(.dataReadout)
            .foregroundColor(Color.mutedText)
    }
    .padding()
    .background(Color.spacePrimary)
}
