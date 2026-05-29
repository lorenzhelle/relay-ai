import SwiftUI

@Observable
final class AppCoordinator {
    var isOnboarded: Bool = false

    private let keychain = KeychainStore.shared

    init() {
        isOnboarded = (try? keychain.loadChannelCredentials()) != nil
    }

    func onboardingComplete() {
        isOnboarded = true
    }

    func resetToOnboarding() {
        keychain.clearAll()
        isOnboarded = false
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
}
