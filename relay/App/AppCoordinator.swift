import SwiftUI

@Observable
final class AppCoordinator {
    var isOnboarded: Bool = false

    private let keychain = KeychainStore.shared

    init() {
        isOnboarded = (try? keychain.loadCredentials()) != nil
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

    var body: some View {
        if coordinator.isOnboarded {
            HomeView()
                .environment(coordinator)
        } else {
            OnboardingRootView()
                .environment(coordinator)
        }
    }
}
