# Dice Rolling System - SW5E iOS

## Overview

This document describes the complete dice rolling system implemented for the Star Wars 5th Edition (SW5E) iOS app. It includes three main components: a thread-safe dice rolling service, haptic feedback manager, and animated roll overlay.

## Components

### 1. DiceRollerService.swift

**Location:** `Sources/SW5E/Services/DiceRollerService.swift`

A thread-safe actor that performs all dice rolling operations locally without external dependencies.

#### Features:
- Supports standard D&D dice: d4, d6, d8, d10, d12, d20, d100
- Modifier support (positive and negative)
- Advantage/disadvantage mechanics (roll twice, take higher/lower)
- Multiple dice rolling for damage calculations
- Automatic critical hit/fail detection on d20 rolls

#### API:

```swift
// Roll a single d20 with optional modifier
let result = await roller.rollD20(modifier: 4, advantage: false, disadvantage: false)

// Custom roll configuration
let result = await roller.rollDice(
    count: 1,
    sides: 20,
    modifier: 4,
    advantage: false,
    disadvantage: false
)

// Damage rolls with multiple dice
let damageResult = await roller.rollDamage(
    diceConfig: [(count: 2, sides: 6), (count: 1, sides: 4)], // 2d6 + 1d4
    modifier: 3
)
```

#### DiceResult Structure:
```swift
struct DiceResult {
    let rolls: [Int]           // Individual die results
    let total: Int             // Sum including modifier
    let modifier: Int          // Applied modifier
    let isCrit: Bool           // Critical hit (d20 = 20)
    let isFail: Bool           // Critical fail (d20 = 1)
    
    var breakdownString: String // "16 + 4 (DEX) = 20"
}
```

### 2. HapticsManager.swift

**Location:** `Sources/SW5E/Services/HapticsManager.swift`

Singleton manager providing haptic feedback for all user interactions using Apple's Feedback Generator APIs.

#### Trigger Points:

| Method | Use Case | Feedback Type |
|--------|----------|---------------|
| `buttonTap()` | Buttons, toggles | Light impact |
| `characterSelection()` | Character cards, menu items | Medium impact |
| `criticalHitSuccess()` | d20 = 20, achievements | Success notification + medium tap |
| `criticalFailError()` | d20 = 1, errors | Error notification |
| `levelUpSuccess()` | Level up events | Success notification + medium combo |
| `uiInteraction()` | Card swipes, list interactions | Light impact |
| `heavyAction()` | Combat actions, major decisions | Medium impact |

#### Usage:

```swift
// Direct call
HapticsManager.shared.buttonTap()

// Via SwiftUI extension (automatic on tap)
Button("Roll") {
    // Action
}
.withHaptic(.light)
```

### 3. DiceRollOverlay.swift

**Location:** `Sources/SW5E/DesignSystem/DiceRollOverlay.swift`

Fullscreen animated overlay that displays dice rolls with professional animations and visual feedback.

#### Features:
- **0.7s rotation animation**: Die face spins before revealing result
- **Color-coded results**: Gold (crit), Red (fail), Blue (high 15+), Orange (low ≤8)
- **Monospace breakdown**: Shows roll math like "16 + 4 (DEX) = 20"
- **Auto-dismiss**: After 2.5 seconds or tap to dismiss manually
- **Spring animations**: Smooth scale transitions

#### Usage:

```swift
// Present overlay via sheet
.sheet(isPresented: $showOverlay) {
    DiceRollOverlay(
        diceResult: result,
        sides: 20,
        modifierDescription: "DEX"
    )
}
```

### 4. Timers.swift

**Location:** `Sources/SW5E/DesignSystem/Timers.swift`

Helper utilities for timer-based animations and delays in SwiftUI views.

## Integration Examples

### Basic Roll with Haptics

```swift
Button(action: {
    HapticsManager.shared.buttonTap()
    
    Task {
        let result = await roller.rollD20(modifier: 4)
        
        if result.isCrit {
            HapticsManager.shared.criticalHitSuccess()
        } else if result.isFail {
            HapticsManager.shared.criticalFailError()
        }
        
        diceResult = result
    }
}) {
    Text("Roll d20")
}
```

### Character Card with Stagger Animation

```swift
ForEach(characters, id: \.id) { character in
    CharacterCardView(character: character)
        .characterCardStagger(index: characters.firstIndex(of: character) ?? 0)
}
```

### Combat Turn Highlight

```swift
Text("Enemy Turn")
    .combatTurnPulse() // Pulsing opacity effect
```

## Color Coding System

Results are color-coded based on quality for instant visual feedback:

- 🟨 **Gold** (`Color.gold`): Critical hit (d20 = 20)
- 🔴 **Sith Red** (`Color.siithRed`): Critical fail (d20 = 1)
- 🔵 **Hologram Blue** (`Color.hologramBlue`): High roll (total ≥ 15)
- 🟠 **Tech Orange** (`Color.techOrange`): Low roll (total ≤ 8)
- ⚪ **Light Text**: Medium rolls (9–14)

## Testing

Run the preview provider to test all components:

```swift
#Preview("Dice Roller Service") {
    DiceRollDemo() // Full interactive demo with haptics
}
```

Or access via ContentView navigation:
- Navigate to "Dice Roller Demo" section
- Test different die types, modifiers, advantage/disadvantage
- Observe color coding and haptic feedback patterns

## Dependencies

All components use only SwiftUI and UIKit — no external dependencies required. The system works offline and requires no network connectivity.

## Future Enhancements

Potential improvements for future iterations:

1. **Sound effects integration**: Add audio cues synchronized with haptics
2. **Roll history**: Track previous rolls in a session
3. **Custom dice skins**: Allow players to choose die face styles
4. **Probability calculator**: Show hit percentages before rolling
5. **Roll modifiers library**: Save common modifier configurations

---

*Last updated: 2026-02-28 | SW5E iOS v1.0*
