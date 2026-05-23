import Foundation

// Orchestrates the full pairing handshake:
//   1. Parse input → extract bot token
//   2. Poll Telegram for /start reply containing pairing code
//   3. After user enters code in Claude Code, poll for confirmation
//   4. Persist credentials to Keychain
final class PairingService {
    static let shared = PairingService()
    private init() {}

    private let telegram = TelegramService.shared
    private let keychain = KeychainStore.shared

    // Step 1: Send /start (by waiting for the bot to receive it) and return the pairing code.
    // The caller is responsible for handling the 90-second expiry on the pairing code screen.
    func requestPairingCode(botInput: String) async throws -> (botToken: String, chatId: String, pairingCode: String) {
        let token = try extractToken(from: botInput)
        let (chatId, code) = try await telegram.sendStartAndGetCode(botToken: token)
        return (botToken: token, chatId: chatId, pairingCode: code)
    }

    // Step 2: Poll until the home computer confirms the code, or until the task is cancelled.
    func waitForConfirmation(botToken: String, chatId: String, pairingCode: String) async throws -> PairingResult {
        var offset = 0
        while true {
            try Task.checkCancellation()
            let (confirmed, nextOffset) = try await telegram.pollForConfirmation(
                botToken: botToken,
                chatId: chatId,
                pairingCode: pairingCode,
                offset: offset
            )
            offset = nextOffset
            if confirmed {
                try keychain.save(botToken: botToken)
                try keychain.save(chatId: chatId)
                try keychain.save(channel: "telegram@claude-plugins-official")
                return PairingResult(
                    botUsername: "@relay_bot",
                    botToken: botToken,
                    chatId: chatId,
                    channel: "telegram@claude-plugins-official",
                    roundTripMs: nil,
                    mcps: []
                )
            }
        }
    }

    // MARK: - Private

    // Accepts: @botname_bot  |  t.me/botname_bot  |  123456:ABCdef-token
    private func extractToken(from input: String) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        // Already a token (digits:alphanum)
        let tokenPattern = /^\d+:[\w-]{20,}$/
        if trimmed.wholeMatch(of: tokenPattern) != nil {
            return trimmed
        }
        // For username inputs, the token lives on the home computer.
        // In practice the user should enter the token directly.
        // Surface a clear error pointing them to the token input mode.
        throw PairingError.usernameNotSupported
    }
}

enum PairingError: LocalizedError {
    case usernameNotSupported
    case invalidInput

    var errorDescription: String? {
        switch self {
        case .usernameNotSupported:
            "Enter the bot token (from BotFather), not the username. Tap 'Token statt Username' below the input."
        case .invalidInput:
            "That doesn't look like a valid bot token or username."
        }
    }
}
