import Foundation
import SwiftUI

/// Sound effects manager for SW5E iOS app.
/// Audio synthesis stubs — sounds will be wired up in a future sprint.
@MainActor
class SoundManager: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = SoundManager()

    // MARK: - Published State

    @Published var isMuted: Bool = false {
        didSet {
            UserDefaults.standard.set(isMuted, forKey: "sw5e_sound_muted")
        }
    }

    @Published var volume: Float = 0.75 {
        didSet {
            UserDefaults.standard.set(volume, forKey: "sw5e_sound_volume")
        }
    }

    // MARK: - Initialization

    override init() {
        super.init()
        isMuted = UserDefaults.standard.bool(forKey: "sw5e_sound_muted")
        let stored = UserDefaults.standard.double(forKey: "sw5e_sound_volume")
        volume = stored > 0 ? Float(stored) : 0.75
    }

    // MARK: - Sound Playback (stubs — TODO: implement AVAudioEngine synthesis)

    func playBlasterShot()   { /* TODO: implement audio */ }
    func startLightsaberHum() { /* TODO: implement audio */ }
    func stopLightsaberHum()  { /* TODO: implement audio */ }
    func playDiceRoll()      { /* TODO: implement audio */ }
    func playXPChime()       { /* TODO: implement audio */ }
    func startAmbientLoop()  { /* TODO: implement audio */ }
    func stopAmbientLoop()   { /* TODO: implement audio */ }
    func stopAllSounds()     { /* TODO: implement audio */ }

    // MARK: - Utility

    func resetDefaults() {
        isMuted = false
        volume = 0.75
    }
}
