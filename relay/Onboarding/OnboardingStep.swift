import Foundation

enum OnboardingStep: Hashable {
    case botInput
    case pairingCode(botToken: String, chatId: String, initialCode: String)
    case paired(PairingResult)
    case triggerPick
    case firstCapture
}
