import SwiftUI

// MARK: - Root Tab View

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: AppTab = .play

    enum AppTab: Hashable {
        case characters, play, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            // Characters tab
            CharacterListView(
                onCharacterTap: { _ in },
                onAddCharacter: { }
            )
            .tabItem {
                Label("Characters", systemImage: "person.2.fill")
            }
            .tag(AppTab.characters)

            // Play tab — Campaign list with AI status indicator
            CampaignListView()
                .tabItem {
                    Label("Play", systemImage: "gamecontroller.fill")
                }
                .tag(AppTab.play)

            // Settings tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
        }
        .tint(.veilGold)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
}
