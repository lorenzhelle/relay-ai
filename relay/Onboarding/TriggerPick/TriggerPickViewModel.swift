import Foundation
import UIKit

enum RelayTrigger {
    case actionButton
    case airpodsStem
    case lockScreenShortcut

    var label: String {
        switch self {
        case .actionButton:       "Action Button"
        case .airpodsStem:        "AirPods · Stem long-press"
        case .lockScreenShortcut: "Lock-Screen Shortcut"
        }
    }

    var hint: String {
        switch self {
        case .actionButton:       "ein Druck · öffnet & nimmt auf"
        case .airpodsStem:        "im Hosentaschen-Modus, hands-free"
        case .lockScreenShortcut: "aus der unteren rechten Ecke"
        }
    }

    var systemImage: String {
        switch self {
        case .actionButton:       "square.circle"
        case .airpodsStem:        "airpods"
        case .lockScreenShortcut: "lock"
        }
    }
}

@Observable
final class TriggerPickViewModel {
    var selected: RelayTrigger = .actionButton

    func select(_ trigger: RelayTrigger) {
        selected = trigger
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func installTrigger() {
        switch selected {
        case .actionButton:
            // Deep-link to Settings → Action Button
            if let url = URL(string: "App-Prefs:ACTION_BUTTON") {
                UIApplication.shared.open(url)
            }
        case .airpodsStem:
            // MPRemoteCommandCenter registration — deferred to main audio session setup
            break
        case .lockScreenShortcut:
            // App Shortcut installation — deferred
            break
        }
    }
}
