# SW5E Design System

Star Wars-themed design system for the SW5E iOS app. Dark space aesthetic with hologram-blue accents and tech-orange highlights.

## Structure

```
Sources/SW5E/DesignSystem/
├── Colors.swift           # Color palette extensions
├── Typography.swift       # Font extensions
└── Components/            # Reusable UI components
    ├── HologramCard.swift      # Dark card with holographic border
    ├── StatBadge.swift         # Ability score pills
    ├── HPBar.swift             # Health point tracker
    ├── DiceRollOverlay.swift   # Fullscreen dice roll animation
    ├── ActionButton.swift      # Primary action button
    └── SectionHeader.swift     # Section headers with Aurebesh style

ViewModifiers.swift          # Custom view modifiers (top-level)
```

## Color Palette

| Name | Hex | Usage |
|------|-----|-------|
| `spacePrimary` | `#0A0E1A` | Main background (near-black) |
| `spaceCard` | `#111827` | Card backgrounds, surfaces |
| `hologramBlue` | `#00D4FF` | Primary accents, borders, highlights |
| `holoBlueSubtle` | `#1A3A4A` | Subtle blue for muted elements |
| `techOrange` | `#E8700A` | Action buttons, tech highlights |
| `siithRed` | `#CC2222` | Danger states, critical HP, enemies |
| `saberGreen` | `#4ADE80` | Positive force effects, safe HP |
| `lightText` | `#E2E8F0` | Primary text on dark backgrounds |
| `mutedText` | `#6B7280` | Secondary/caption text |
| `borderSubtle` | `#1F2937` | Borders and dividers |

## Typography

| Style | Usage | Notes |
|-------|-------|-------|
| `.starWarsTitle` | Main titles | Large + bold, tracking 2 |
| `.holoDisplay` | Headlines | Monospaced (SF Mono), semibold |
| `.dataReadout` | Numbers/stats | Strictly monospaced for alignment |
| `.bodyText` | Narrative text | Regular weight, letter spacing |
| `.labelSmall` | Badges/tags | Caption2, medium weight |

## Components

### HologramCard
Dark card with holographic blue border and glow effect. Tap to see hover state.

```swift
HologramCard(title: "Character Stats", content: "Strength +3")
```

### StatBadge
Compact pill for ability scores showing label + value/modifier.

```swift
StatBadge(label: "Dexterity", value: 14, modifier: true)
```

### HPBar
Dynamic health bar with color interpolation (green→orange→red).

```swift
HPBar(current: 22, maximum: 45)
```

### DiceRollOverlay
Fullscreen overlay showing animated dice roll results. Dismisses on tap or timeout.

```swift
DiceRollOverlay(sides: 20, rolls: [18], modifier: 4, total: 22)
```

### ActionButton
Primary action button with holographic border and press animation.

```swift
ActionButton(title: "Attack", icon: "⚔️", action: { /* ... */ })
```

### SectionHeader
Section header with left accent bar and small caps title.

```swift
SectionHeader(title: "Character Vitals")
```

## View Modifiers

| Modifier | Effect |
|----------|--------|
| `.holoCard()` | Dark background + holographic border |
| `.glowEffect(color:)` | Colored shadow glow |
| `.hologramBorder(active:)` | Blue border with optional active state |
| `.dataReadout()` | Monospaced data styling |
| `.mutedText()` | Secondary text color |
| `.holoBackground()` | Subtle blue gradient background |

## Usage Guidelines

1. **Never use white backgrounds** - All surfaces must be dark space colors
2. **Use hologramBlue for primary actions** - This is your accent color
3. **TechOrange for secondary highlights** - Buttons, important data points
4. **SithRed only for danger states** - Low HP, critical failures, enemy indicators
5. **Monospaced fonts for numbers** - Ensures alignment in tables and stats

## Future Additions

- [ ] Colorblind accessibility modes
- [ ] Dynamic type support
- [ ] Dark/light theme variants (if needed)
- [ ] More component variations (large/small sizes)
