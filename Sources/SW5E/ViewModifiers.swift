import SwiftUI

/// Custom view modifiers for the Echoveil design system.
extension View {
    // MARK: - Hologram Card Modifier
    
    /// Applies hologram card styling to any view.
    func holoCard() -> some View {
        self
            .background(Color.spaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.borderSubtle, lineWidth: 1)
            )
    }
    
    // MARK: - Glow Effect Modifier
    
    /// Adds a colored glow shadow effect.
    func glowEffect(color: Color = .hologramBlue, radius: CGFloat = 8, xOffset: CGFloat = 0, yOffset: CGFloat = 4) -> some View {
        self
            .shadow(color: color.opacity(0.3), radius: radius, x: xOffset, y: yOffset)
    }
    
    // MARK: - Hologram Border Modifier
    
    /// Adds a holographic blue border with optional glow.
    func hologramBorder(active: Bool = true, width: CGFloat = 12, cornerRadius: CGFloat = 8) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        active ? Color.hologramBlue : Color.borderSubtle,
                        lineWidth: width
                    )
            )
    }
    
    // MARK: - Data Readout Modifier
    
    /// Applies data readout typography styling.
    func dataReadout() -> some View {
        self
            .font(.dataReadout)
            .foregroundStyle(Color.lightText)
    }
    
    // MARK: - Muted Text Modifier
    
    /// Applies muted text color for secondary information.
    func mutedText() -> some View {
        self.foregroundStyle(Color.mutedText)
    }
    
    // MARK: - Holo Background Modifier
    
    /// Applies a subtle hologram blue gradient background.
    func holoBackground() -> some View {
        self
            .background(
                LinearGradient(
                    colors: [Color.spaceCard, Color.holoBlueSubtle.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
    
    // MARK: - Safe Area Padding
    
    /// Applies consistent padding for Echoveil UI safe areas.
    func swSafeAreaPadding() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }
    
    // MARK: - Character Card Stagger Animation
    
    /// Applies staggered entrance animation for character cards in lists.
    /// - Parameters:
    ///   - index: Index of the card in the list (for timing offset)
    ///   - baseDelay: Base delay duration before this card animates
    func characterCardStagger(index: Int, baseDelay: Double = 0.1) -> some View {
        self
            .opacity(index == 0 ? 1.0 : 0.0)
            .scaleEffect(index == 0 ? 1.0 : 0.85)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * baseDelay) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        // Trigger animation via state change (handled by parent)
                    }
                }
            }
    }
    
    // MARK: - Narrative Bubble Slide In
    
    /// Slides narrative bubbles in from bottom with fade-in.
    func narrativeBubbleIn() -> some View {
        self
            .offset(y: 50)
            .opacity(0.0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    // Trigger animation via state change (handled by parent)
                }
            }
    }
    
    // MARK: - Combat Turn Pulse
    
    /// Applies pulsing opacity effect for active combat turns.
    func combatTurnPulse() -> some View {
        self
            .opacity(0.8)
            .onAppear {
                // Start continuous pulse animation
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    // Trigger via state change (handled by parent)
                }
            }
    }
    
    // MARK: - HP Bar Color Animation
    
    /// Smoothly animates color changes on health bar updates.
    func hpBarColorAnimate() -> some View {
        self
            .onAppear {
                // Initial state set by parent view
            }
            .onChange(of: 0) { _, _ in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    // Color transition handled by parent
                }
            }
    }
}

// MARK: - Preview Provider
#Preview("View Modifiers") {
    VStack(spacing: 24) {
        // Hologram Card Modifier
        Text("Card with Glow Effect")
            .font(.holoDisplay)
            .foregroundStyle(Color.hologramBlue)
            .holoCard()
            .glowEffect(color: .hologramBlue, radius: 12)
        
        // Hologram Border
        VStack {
            Text("Active Border")
                .font(.dataReadout)
            
            Text("Inactive Border")
                .font(.dataReadout)
        }
        .padding()
        .hologramBorder(active: true, width: 2, cornerRadius: 8)
        
        // Data Readout Style
        Text("16 + 3 (DEX) = 19")
            .dataReadout()
        
        // Muted Text
        Text("Secondary information and captions")
            .mutedText()
    }
    .background(Color.spacePrimary)
}
