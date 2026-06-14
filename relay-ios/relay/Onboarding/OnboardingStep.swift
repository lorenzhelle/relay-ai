import Foundation

enum OnboardingStep: Hashable {
    case triggerPick
    case channelId(String)
    case firstCapture
}
