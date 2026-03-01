import SwiftUI

/// Health point tracker with dynamic color interpolation based on HP percentage.
/// Green at full health → orange at 50% → red below 25%.
struct HPBar: View {
    let current: Int
    let maximum: Int
    var barHeight: CGFloat

    init(current: Int, maximum: Int, size: CGFloat = 8) {
        self.current = current
        self.maximum = maximum
        self.barHeight = size
    }

    // Alias init for CombatOverlayView / CharacterSidebarDrawer call sites
    init(currentHp: Int, maxHp: Int, size: CGFloat = 8) {
        self.current = currentHp
        self.maximum = maxHp
        self.barHeight = size
    }
    
    var hpPercentage: Double {
        guard maximum > 0 else { return 1.0 }
        return Double(current) / Double(maximum)
    }
    
    var barColor: Color {
        switch hpPercentage {
        case 0..<0.25:
            return .voidRed // Critical - red
        case 0.25..<0.5:
            return .veilPurple // Warning - orange
        default:
            return .veilGlow // Safe - green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text("HP")
                    .font(.labelSmall)
                    .foregroundStyle(Color.mutedText)
                
                Spacer()
                
                Text("\(current)/\(maximum)")
                    .font(.dataReadout)
                    .fontWeight(.bold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.borderSubtle)
                    
                    // HP fill with smooth animation
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor.gradient)
                        .frame(width: geometry.size.width * hpPercentage, height: barHeight)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: current)
                }
            }
            .frame(height: barHeight)
        }
    }
}

// MARK: - Preview Provider
#Preview("HP Bar - Full") {
    HPBar(current: 45, maximum: 45)
        .padding()
}

#Preview("HP Bar - Warning") {
    HPBar(current: 22, maximum: 45)
        .padding()
}

#Preview("HP Bar - Critical") {
    HPBar(current: 8, maximum: 45)
        .padding()
}
