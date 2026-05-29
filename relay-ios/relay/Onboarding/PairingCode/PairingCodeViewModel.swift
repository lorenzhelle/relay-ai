import Foundation
import UIKit

@Observable
final class PairingCodeViewModel {
    var codeInput: String = ""
    var isConfirming: Bool = false
    var errorMessage: String? = nil

    private let pairing = PairingService.shared

    var trimmedCode: String {
        codeInput.trimmingCharacters(in: .whitespaces).uppercased()
    }

    var canConfirm: Bool { trimmedCode.count == 6 }

    func confirm(onSuccess: @escaping (PairingResult) -> Void) {
        guard canConfirm else { return }
        errorMessage = nil
        isConfirming = true
        Task {
            defer { isConfirming = false }
            do {
                let result = try await pairing.pair(code: trimmedCode)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onSuccess(result)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
