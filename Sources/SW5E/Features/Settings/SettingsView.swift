import SwiftUI

// MARK: - Settings View

/// Server configuration, AI backend status, sound, and about sections.
struct SettingsView: View {
    @AppStorage("serverURL") private var serverURL: String = "https://sw5e-api.petieclark.com"

    // SoundManager accessed via shared singleton — no environment injection required
    @StateObject private var soundManager = SoundManager.shared
    @StateObject private var connectionChecker = ConnectionChecker()

    @State private var editingServerURL = false
    @State private var draftServerURL = ""
    @State private var showingSoundInfo = false

    var body: some View {
        NavigationStack {
            Form {
                serverSection
                aiBackendSection
                soundSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.spacePrimary.ignoresSafeArea())
            .navigationTitle("Settings ⚙️")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Sync persisted URL into APIService on every appearance
            APIService.shared.serverURL = serverURL
        }
    }

    // MARK: - Server Configuration Section

    private var serverSection: some View {
        Section {
            // URL row
            if editingServerURL {
                HStack {
                    TextField("http://localhost:3001", text: $draftServerURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(.lightText)
                        .font(.system(.subheadline, design: .monospaced))

                    Button {
                        serverURL = draftServerURL
                        APIService.shared.serverURL = draftServerURL
                        editingServerURL = false
                        Task { await connectionChecker.checkConnection() }
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.saberGreen)
                            .font(.title3)
                    }

                    Button {
                        editingServerURL = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.siithRed)
                            .font(.title3)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "server.rack")
                        .foregroundColor(.hologramBlue)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Server URL")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.lightText)
                        Text(serverURL)
                            .font(.caption.monospaced())
                            .foregroundColor(.mutedText)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        draftServerURL = serverURL
                        editingServerURL = true
                    } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(.techOrange)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Connection check row
            HStack {
                Button {
                    Task { await connectionChecker.checkConnection() }
                } label: {
                    Label("Check Connection", systemImage: "wifi")
                        .font(.subheadline)
                        .foregroundColor(.hologramBlue)
                }
                .buttonStyle(.plain)

                Spacer()

                if connectionChecker.isChecking {
                    ProgressView().scaleEffect(0.75)
                } else {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(connectionChecker.isConnected ? Color.saberGreen : Color.siithRed)
                            .frame(width: 8, height: 8)
                        Text(connectionChecker.isConnected ? "Connected" : "Offline")
                            .font(.caption)
                            .foregroundColor(connectionChecker.isConnected ? .saberGreen : .siithRed)
                    }
                }
            }
        } header: {
            Label("Server Configuration", systemImage: "server.rack.fill")
                .foregroundColor(.hologramBlue)
        } footer: {
            Text("Set the address of your SW5E backend. Default: https://sw5e-api.petieclark.com")
                .foregroundColor(.mutedText)
        }
        .listRowBackground(Color.spaceCard)
    }

    // MARK: - AI Backend Status Section

    private var aiBackendSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.hologramBlue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Game Master")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.lightText)
                    Text("Via server /api/ai/status")
                        .font(.caption)
                        .foregroundColor(.mutedText)
                }

                Spacer()

                if connectionChecker.isChecking {
                    ProgressView().scaleEffect(0.75)
                } else {
                    aiStatusBadge
                }
            }

            Text(connectionChecker.aiStatusDescription)
                .font(.caption)
                .foregroundColor(.mutedText)
        } header: {
            Label("AI Backend", systemImage: "cpu.fill")
                .foregroundColor(.hologramBlue)
        } footer: {
            Text("The AI GM generates narrative, descriptions, and NPC dialogue in real-time using the configured server.")
                .foregroundColor(.mutedText)
        }
        .listRowBackground(Color.spaceCard)
    }

    @ViewBuilder
    private var aiStatusBadge: some View {
        if connectionChecker.aiOnline {
            Label("Online", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundColor(.saberGreen)
        } else {
            Label("Offline", systemImage: "xmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundColor(.siithRed)
        }
    }

    // MARK: - Sound Section

    private var soundSection: some View {
        Section {
            // Mute toggle
            Toggle(isOn: $soundManager.isMuted) {
                Label("Sound Effects", systemImage: soundManager.isMuted ? "speaker.slash.fill" : "speaker.fill")
                    .foregroundColor(soundManager.isMuted ? .mutedText : .lightText)
            }
            .tint(.hologramBlue)

            // Volume slider — hidden when muted
            if !soundManager.isMuted {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "speaker.wave.1")
                            .foregroundColor(.mutedText)
                            .font(.caption)
                        Slider(value: $soundManager.volume, in: 0...1, step: 0.05)
                            .tint(.hologramBlue)
                        Image(systemName: "speaker.wave.3")
                            .foregroundColor(.hologramBlue)
                            .font(.caption)
                    }

                    HStack {
                        Text("Volume: \(Int(soundManager.volume * 100))%")
                            .font(.caption)
                            .foregroundColor(.mutedText)
                        Spacer()
                        HStack(spacing: 8) {
                            presetButton("Low", value: 0.25)
                            presetButton("Med", value: 0.5)
                            presetButton("High", value: 1.0)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // Sound info toggle
            Button {
                withAnimation(.spring(response: 0.35)) {
                    showingSoundInfo.toggle()
                }
            } label: {
                HStack {
                    Text(showingSoundInfo ? "Hide sound details" : "Show sound details")
                        .font(.subheadline)
                        .foregroundColor(.techOrange)
                    Spacer()
                    Image(systemName: showingSoundInfo ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.mutedText)
                }
            }
            .buttonStyle(.plain)

            if showingSoundInfo {
                VStack(spacing: 8) {
                    SoundEffectRow(
                        icon: "waveform.and.sparkles",
                        title: "Lightsaber Hum",
                        description: "Dual-oscillator hum with FM modulation. Plays for force-sensitive classes.",
                        color: .saberGreen
                    )
                    SoundEffectRow(
                        icon: "bolt.fill",
                        title: "Blaster Shot",
                        description: "White noise + 800→300 Hz sweep. Plays on combat actions.",
                        color: .techOrange
                    )
                    SoundEffectRow(
                        icon: "die.face.6.fill",
                        title: "Dice Roll",
                        description: "Randomised frequency bursts simulating rattling dice.",
                        color: .hologramBlue
                    )
                    SoundEffectRow(
                        icon: "sparkles",
                        title: "XP Chime",
                        description: "C-major arpeggio (C5–E5–G5–C6) with harmonic overtones on level-up.",
                        color: .saberGreen
                    )
                }
                .padding(.vertical, 4)
            }
        } header: {
            Label("Sound Effects", systemImage: "speaker.fill")
                .foregroundColor(.hologramBlue)
        }
        .listRowBackground(Color.spaceCard)
    }

    private func presetButton(_ label: String, value: Float) -> some View {
        Button {
            withAnimation { soundManager.volume = value }
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.hologramBlue)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.hologramBlue.opacity(0.15)))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.hologramBlue.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Label("Version", systemImage: "info.circle")
                    .foregroundColor(.lightText)
                Spacer()
                Text(appVersion)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.mutedText)
            }

            HStack {
                Label("SW5E Companion App", systemImage: "star.fill")
                    .foregroundColor(.lightText)
                Spacer()
                Text("⚔️")
            }

            Link(destination: URL(string: "https://github.com/petieclark/sw5e-ios")!) {
                Label("Source on GitHub", systemImage: "link")
                    .foregroundColor(.hologramBlue)
            }

            Link(destination: URL(string: "https://www.sw5e.com")!) {
                Label("SW5E Ruleset", systemImage: "book.closed.fill")
                    .foregroundColor(.hologramBlue)
            }

            Link(destination: URL(string: "https://github.com/petieclark/sw5e-ios/blob/main/LICENSE")!) {
                Label("MIT License", systemImage: "doc.text.fill")
                    .foregroundColor(.hologramBlue)
            }

            // Reset
            Button(role: .destructive) {
                soundManager.resetDefaults()
                serverURL = "https://sw5e-api.petieclark.com"
                APIService.shared.serverURL = "https://sw5e-api.petieclark.com"
            } label: {
                Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                    .foregroundColor(.siithRed)
            }
        } header: {
            Label("About", systemImage: "info.circle.fill")
                .foregroundColor(.hologramBlue)
        }
        .listRowBackground(Color.spaceCard)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

// MARK: - Connection Checker ViewModel

@MainActor
final class ConnectionChecker: ObservableObject {
    @Published var isChecking = false
    @Published var isConnected = false
    @Published var aiOnline: Bool = false
    @Published var aiStatusDescription: String = "Checking AI backend availability…"

    private let api = APIService.shared

    init() {
        Task { await checkConnection() }
    }

    func checkConnection() async {
        isChecking = true
        defer { isChecking = false }

        // Check main backend
        isConnected = await api.checkConnection()

        // Check AI via the real /api/ai/status endpoint
        let status = await api.checkAIStatus()
        aiOnline = status.available
        if status.available {
            aiStatusDescription = status.message ?? "AI Game Master is ready. Narrative generation enabled."
        } else {
            aiStatusDescription = status.message ?? "AI backend offline. Start Ollama or LM Studio on the server."
        }
    }
}

// MARK: - Sound Effect Row

private struct SoundEffectRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.lightText)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .background(Color.spacePrimary.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Previews

#Preview("Settings") {
    SettingsView()
}

#Preview("Sound Effect Row") {
    VStack(spacing: 8) {
        SoundEffectRow(icon: "waveform.and.sparkles", title: "Lightsaber Hum",
                       description: "Dual-oscillator hum with FM modulation.", color: .saberGreen)
        SoundEffectRow(icon: "bolt.fill", title: "Blaster Shot",
                       description: "White noise + frequency sweep.", color: .techOrange)
    }
    .padding()
    .background(Color.spacePrimary)
    .preferredColorScheme(.dark)
}
