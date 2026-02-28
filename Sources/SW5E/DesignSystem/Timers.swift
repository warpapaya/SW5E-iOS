import SwiftUI
import Combine

/// Custom ViewPropertyWrapper for timer-based animations and delays.
/// Provides a cleaner syntax than DispatchQueue.main.asyncAfter in SwiftUI views.
@propertyWrapper
struct TimerState: DynamicProperty {
    @State private var timer: Timer?
    
    var wrappedValue: Timer? {
        get { timer }
        set {
            timer?.invalidate()
            timer = newValue
        }
    }
    
    var projectedValue: Binding<Timer?> {
        Binding(
            get: { self.timer },
            set: { self.timer = $0 }
        )
    }
    
    init(wrappedValue: Timer?) {
        _timer = State(initialValue: wrappedValue)
    }
}

/// Extension for starting delayed timers from views without manual timer management.
extension View {
    /// Executes an action after a delay, automatically managing the timer lifecycle.
    /// - Parameters:
    ///   - delay: Time to wait before executing the action (in seconds)
    ///   - repeats: Whether to repeat the action every `delay` interval
    ///   - action: The closure to execute when timer fires
    @ViewBuilder func onTimer(delay: TimeInterval, repeats: Bool = false, perform action: @escaping () -> Void) -> some View {
        self
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: delay, repeats: repeats) { _ in
                    action()
                }
            }
    }
    
    /// Executes an action once after a delay.
    func afterDelay(_ delay: TimeInterval, perform action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            action()
        }
    }
}

// MARK: - Preview Provider
#Preview("Timer Extensions") {
    VStack(spacing: 20) {
        Text("Testing timer delays...")
            .font(.headline)

        Button(action: {
            print("Button tapped!")
        }) {
            Text("Tap me")
                .padding()
                .background(Color.hologramBlue)
                .foregroundColor(.spacePrimary)
                .cornerRadius(8)
        }
    }
    .onAppear {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            print("Repeating every 2 seconds")
        }
    }
}
