import SwiftUI
import AVFoundation

@MainActor
@Observable
final class AppCoordinator {
    var isOnboarded: Bool = false

    private let keychain = KeychainStore.shared
    private let synth = AVSpeechSynthesizer()

    init() {
        isOnboarded = (try? keychain.loadChannelCredentials()) != nil
    }

    func onboardingComplete() {
        isOnboarded = true
        startRelay()
    }

    func resetToOnboarding() {
        RelayCaptureService.shared.stopListening()
        keychain.clearAll()
        isOnboarded = false
    }

    // MARK: - Relay connection

    /// Start the Realtime WebSocket after onboarding (or on cold launch when already paired).
    @MainActor
    func startRelay() {
        guard let creds = try? keychain.loadChannelCredentials() else { return }
        let anonKey = RelayChannelService.supabaseAnonKey
        guard !anonKey.isEmpty else { return }

        RelayCaptureService.shared.startListening(
            channelId: creds.channelId,
            supabaseURL: RelayChannelService.supabaseURL,
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
        }
    }

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synth.speak(utterance)
    }
}

struct AppCoordinatorView: View {
    @State private var coordinator = AppCoordinator()
    @State private var captureStore: CaptureStore
    @State private var whisperService: WhisperService
    @State private var captureVM: CaptureViewModel

    init() {
        let store = CaptureStore()
        let whisper = WhisperService()
        _captureStore = State(initialValue: store)
        _whisperService = State(initialValue: whisper)
        _captureVM = State(initialValue: CaptureViewModel(whisper: whisper, store: store))
    }

    var body: some View {
        Group {
            if coordinator.isOnboarded {
                HomeView()
                    .environment(coordinator)
                    .environment(captureStore)
                    .environment(captureVM)
            } else {
                OnboardingRootView()
                    .environment(coordinator)
            }
        }
        .task {
            // On cold launch when already paired, open the WebSocket immediately.
            if coordinator.isOnboarded {
                coordinator.startRelay()
            }
        }
    }
}
