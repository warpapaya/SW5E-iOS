import SwiftUI

// MARK: - AI Status Indicator

/// Green/red pulsing dot showing AI backend availability.
/// Tap to retry when red.
struct AIStatusIndicator: View {
    let isAvailable: Bool
    let onRetry: () -> Void

    @State private var isPulsing = false

    private var dotColor: Color { isAvailable ? .veilGlow : .voidRed }
    private var label: String    { isAvailable ? "AI Online" : "AI Offline" }

    var body: some View {
        Button(action: { if !isAvailable { onRetry() } }) {
            HStack(spacing: 6) {
                ZStack {
                    // Outer pulse ring
                    Circle()
                        .fill(dotColor.opacity(0.25))
                        .frame(width: 18, height: 18)
                        .scaleEffect(isPulsing ? 1.6 : 1.0)
                        .opacity(isPulsing ? 0 : 0.6)

                    // Core dot
                    Circle()
                        .fill(dotColor)
                        .frame(width: 10, height: 10)
                }

                Text(label)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(dotColor)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.4)
                .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
        .onChange(of: isAvailable) { _, _ in
            isPulsing = false
            // restart pulse after state change
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(
                    .easeInOut(duration: 1.4)
                    .repeatForever(autoreverses: false)
                ) {
                    isPulsing = true
                }
            }
        }
        .accessibilityLabel(label)
        .accessibilityHint(isAvailable ? "" : "Tap to retry connection")
    }
}

#Preview("AI Online") {
    HStack(spacing: 24) {
        AIStatusIndicator(isAvailable: true, onRetry: {})
        AIStatusIndicator(isAvailable: false, onRetry: {})
    }
    .padding()
    .background(Color.spacePrimary)
}
