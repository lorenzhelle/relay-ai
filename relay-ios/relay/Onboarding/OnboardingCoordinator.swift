import SwiftUI

@Observable
final class OnboardingCoordinator {
    var path: [OnboardingStep] = []

    func advance(to step: OnboardingStep) {
        path.append(step)
    }

    func reset() {
        path = []
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
