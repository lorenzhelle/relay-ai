import Foundation

@Observable
final class BotInputViewModel {
    var botInput: String = ""
    var isLoading: Bool = false
    var errorMessage: String? = nil

    private let pairing = PairingService.shared

    var isInputValid: Bool {
        let t = botInput.trimmingCharacters(in: .whitespaces)
        if t.isEmpty { return false }
        // Bot token: digits:alphanum (35+ chars after colon)
        if (try? /^\d+:[\w-]{20,}$/.wholeMatch(in: t)) != nil { return true }
        // Username: @name_bot or name_bot
        if (try? /^@?[a-zA-Z0-9_]{5,}_bot$/.wholeMatch(in: t)) != nil { return true }
        // t.me/name_bot URL
        if (try? /^(https?:\/\/)?t\.me\/[a-zA-Z0-9_]+/.wholeMatch(in: t)) != nil { return true }
        print("is Input not valid: \(t)")
        return false
    }

    func submit(onSuccess: @escaping (String, String, String) -> Void) {
        guard isInputValid else { return }
        errorMessage = nil
        isLoading = true

        Task {
            defer { isLoading = false }
            do {
                let (token, chatId, code) = try await pairing.requestPairingCode(botInput: botInput)
                onSuccess(token, chatId, code)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
