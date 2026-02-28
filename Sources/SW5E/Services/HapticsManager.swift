import Foundation
import SwiftUI
import UIKit

/// Manager for haptic feedback in the SW5E iOS app.
final class HapticsManager {

    static let shared = HapticsManager()

    private var impactLight:  UIImpactFeedbackGenerator?
    private var impactMedium: UIImpactFeedbackGenerator?
    private var notification: UINotificationFeedbackGenerator?

    private init() {
        impactLight  = UIImpactFeedbackGenerator(style: .light)
        impactMedium = UIImpactFeedbackGenerator(style: .medium)
        notification = UINotificationFeedbackGenerator()
        impactLight?.prepare()
        impactMedium?.prepare()
        notification?.prepare()
    }

    func buttonTap() {
        impactLight?.impactOccurred()
        impactLight?.prepare()
    }

    func characterSelection() {
        impactMedium?.impactOccurred()
        impactMedium?.prepare()
    }

    func criticalHitSuccess() {
        notification?.notificationOccurred(.success)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000)
            impactMedium?.impactOccurred()
        }
    }

    func criticalFailError() {
        notification?.notificationOccurred(.error)
    }

    func levelUpSuccess() {
        notification?.notificationOccurred(.success)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            impactMedium?.impactOccurred()
        }
    }

    func uiInteraction() {
        impactLight?.impactOccurred()
        impactLight?.prepare()
    }

    func heavyAction() {
        impactMedium?.impactOccurred()
        impactMedium?.prepare()
    }
}

// MARK: - Convenience SwiftUI Extension

enum HapticType { case light, medium, success, error }

extension View {
    func withHaptic(_ type: HapticType = .light) -> some View {
        self.onTapGesture {
            switch type {
            case .light:   HapticsManager.shared.buttonTap()
            case .medium:  HapticsManager.shared.characterSelection()
            case .success: HapticsManager.shared.criticalHitSuccess()
            case .error:   HapticsManager.shared.criticalFailError()
            }
        }
    }
}

// MARK: - Preview

#Preview("Haptics Manager") {
    VStack(spacing: 20) {
        Text("Tap each button to test haptic feedback")
            .font(.headline)

        Button("Button Tap (Light)") { HapticsManager.shared.buttonTap() }
            .padding()
            .background(Color.hologramBlue)
            .foregroundColor(Color.spacePrimary)
            .cornerRadius(8)

        Button("Character Selection (Medium)") { HapticsManager.shared.characterSelection() }
            .padding()
            .background(Color.techOrange)
            .foregroundColor(Color.spacePrimary)
            .cornerRadius(8)

        Button("Critical Hit") { HapticsManager.shared.criticalHitSuccess() }
            .padding()
            .background(Color.saberGreen)
            .foregroundColor(Color.spacePrimary)
            .cornerRadius(8)

        Button("Critical Fail") { HapticsManager.shared.criticalFailError() }
            .padding()
            .background(Color.siithRed)
            .foregroundColor(Color.lightText)
            .cornerRadius(8)
    }
    .padding()
}
