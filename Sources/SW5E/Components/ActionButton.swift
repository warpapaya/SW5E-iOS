import SwiftUI

/// Holographic action button with dark background and accent-colored text.
struct ActionButton: View {
    let title: String
    var icon: String?
    var isLoading: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = false }
            }
            if !isLoading { action() }
        }) {
            HStack(spacing: icon == nil ? 0 : 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .lightText))
                } else {
                    if let icon = icon {
                        Text(icon).font(.system(size: 16, weight: .semibold))
                    }
                    Text(title).font(.holoDisplay)
                }
            }
            .foregroundColor(isPressed ? .hologramBlue : .lightText)
            .padding(.horizontal, icon == nil ? 20 : 16)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.spaceCard))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isPressed ? Color.hologramBlue : Color.borderSubtle,
                        lineWidth: isPressed ? 2 : 1
                    )
                    .animation(.spring(response: 0.2), value: isPressed)
            )
        }
        .disabled(isLoading)
    }
}

// MARK: - Preview
#Preview("Action Button") {
    VStack(spacing: 16) {
        ActionButton(title: "Roll Dice", action: {})
        ActionButton(title: "Attack", icon: "⚔️", action: {})
        ActionButton(title: "Loading...", isLoading: true, action: {})
    }
    .padding()
}
