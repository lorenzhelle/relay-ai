import SwiftUI
import AVFoundation

@MainActor
@Observable
final class AppCoordinator {
    var isOnboarded: Bool = false

    private let keychain = KeychainStore.shared
    private let synth = AVSpeechSynthesizer()

    init() {
        isOnboarded = (try? keychain.loadChannelId()) != nil
    }

    func onboardingComplete() {
        // ChannelIdView already saved the channelId to Keychain before calling here.
        isOnboarded = true
        startRelay()
    }

    func resetToOnboarding() {
        RelayCaptureService.shared.stopListening()
        keychain.clearAll()
        isOnboarded = false
    }

    // MARK: - Relay connection

    /// Start the Realtime WebSocket after onboarding (or on cold launch when already onboarded).
    @MainActor
    func startRelay() {
        guard let channelId = try? keychain.loadChannelId() else { return }
        let anonKey = SupabaseConfig.anonKey
        guard !anonKey.isEmpty else { return }

        RelayCaptureService.shared.startListening(
            channelId: channelId,
            supabaseURL: SupabaseConfig.url,
            anonKey: anonKey
        ) { [weak self] event in
            self?.handle(event: event)
        }
    }

    // MARK: - Incoming events

    @MainActor
    private func handle(event: RelayEvent) {
        switch event {
        case .ack:
            // Ack is handled by CaptureViewModel (status update) — nothing to do here.
            break
        case .speak(_, let text):
            speak(text)
        case .text:
            // Text-only reply: displayed via CaptureViewModel's handler; no TTS.
            break
        }
    }

    func speak(_ text: String) {
        // Reconfigure the audio session for playback — the recorder leaves it in .record mode.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        // AVSpeechSynthesisVoice expects BCP-47 format ("en-US"), not Locale's underscore form ("en_US").
        let langTag = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
        utterance.voice = AVSpeechSynthesisVoice(language: langTag)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synth.speak(utterance)
    }
}

struct AppCoordinatorView: View {
    @State private var coordinator = AppCoordinator()
    @State private var captureStore: CaptureStore
    @State private var speechService: SpeechTranscriptionService
    @State private var captureVM: CaptureViewModel
    @State private var settings = RelaySettings()

    init() {
        let store = CaptureStore()
        let speech = SpeechTranscriptionService()
        _captureStore = State(initialValue: store)
        _speechService = State(initialValue: speech)
        _captureVM = State(initialValue: CaptureViewModel(speech: speech, store: store))
    }

    var body: some View {
        Group {
            if coordinator.isOnboarded {
                HomeView()
                    .environment(coordinator)
                    .environment(captureStore)
                    .environment(captureVM)
                    .environment(settings)
            } else {
                OnboardingRootView()
                    .environment(coordinator)
            }
        }
        .task {
            // On cold launch when already onboarded, open the WebSocket immediately.
            if coordinator.isOnboarded {
                coordinator.startRelay()
            }
            // Wire the settings object into the view model so sendCapture can read voiceMode.
            captureVM.settings = settings
        }
    }
}
