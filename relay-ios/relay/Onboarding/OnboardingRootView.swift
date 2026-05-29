import SwiftUI

struct OnboardingRootView: View {
    @State private var coordinator = OnboardingCoordinator()
    @Environment(AppCoordinator.self) private var appCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            WelcomeView()
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .pairingCode:
                        PairingCodeView()
                    case .paired(let result):
                        PairedView(result: result)
                    case .triggerPick:
                        TriggerPickView()
                    case .firstCapture:
                        FirstCaptureView()
                    }
                }
        }
        .environment(coordinator)
        .tint(Color.relayInk)
        .onAppear { applyNavBarAppearance() }
    }

    private func applyNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.relayBg)
        appearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
