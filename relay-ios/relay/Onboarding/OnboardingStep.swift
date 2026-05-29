import Foundation

enum OnboardingStep: Hashable {
    case pairingCode
    case paired(PairingResult)
    case triggerPick
    case firstCapture
}
