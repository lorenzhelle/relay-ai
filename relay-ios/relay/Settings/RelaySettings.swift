import Foundation

private let kVoiceMode = "relay.voiceMode"

@MainActor
@Observable
final class RelaySettings {
    var voiceMode: Bool {
        didSet { UserDefaults.standard.set(voiceMode, forKey: kVoiceMode) }
    }

    init() {
        // Default to true — first launch behaves like voice mode.
        if UserDefaults.standard.object(forKey: kVoiceMode) == nil {
            voiceMode = true
        } else {
            voiceMode = UserDefaults.standard.bool(forKey: kVoiceMode)
        }
    }
}
