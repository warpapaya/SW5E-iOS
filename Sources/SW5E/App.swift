import SwiftUI

@main
struct EchoveilApp: App {
    @StateObject private var appState = AppState.shared

    init() {
        // Set up the shared app state
        _appState = StateObject(wrappedValue: AppState.shared)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
