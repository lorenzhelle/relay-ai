import Foundation

private let kVoiceMode = "relay.voiceMode"
private let kTapMode   = "relay.tapMode"

@MainActor
@Observable
final class RelaySettings {
    var voiceMode: Bool {
        didSet { UserDefaults.standard.set(voiceMode, forKey: kVoiceMode) }
    }
    /// When true: tap once to start, tap again to send. When false: hold to record.
    var tapMode: Bool {
        didSet { UserDefaults.standard.set(tapMode, forKey: kTapMode) }
    }

    init() {
        if UserDefaults.standard.object(forKey: kVoiceMode) == nil {
            voiceMode = true
        } else {
            voiceMode = UserDefaults.standard.bool(forKey: kVoiceMode)
        }
        tapMode = UserDefaults.standard.bool(forKey: kTapMode)
    }
}
