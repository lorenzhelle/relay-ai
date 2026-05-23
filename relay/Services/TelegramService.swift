import Foundation

// Thin wrapper around the Telegram Bot API.
// All methods throw TelegramError on network or API failures.
final class TelegramService {
    static let shared = TelegramService()
    private init() {}

    private let session = URLSession.shared
    private let base = "https://api.telegram.org"

    // Send /start to the bot. Returns the user's chat-id and the pairing code
    // that the home computer replied with.
    // The home computer is expected to respond to /start with a message
    // containing a line matching "PAIRING_CODE: <code>".
    func sendStartAndGetCode(botToken: String) async throws -> (chatId: String, pairingCode: String) {
        // Long-poll getUpdates for a message from any user that starts the bot.
        // In practice the user taps "send" right after opening Telegram and sending /start,
        // so we wait up to 60 s.
        let updates = try await getUpdates(botToken: botToken, offset: 0, timeout: 60)
        for update in updates {
            if let text = update.message?.text,
               let chatId = update.message?.chat.id.description,
               let code = extractPairingCode(from: text) {
                return (chatId: chatId, pairingCode: code)
            }
        }
        throw TelegramError.noPairingCodeReceived
    }

    // Long-poll for a confirmation message from the home computer.
    // Returns true when the bot confirms the pairing code was accepted.
    func pollForConfirmation(
        botToken: String,
        chatId: String,
        pairingCode: String,
        offset: Int
    ) async throws -> (confirmed: Bool, nextOffset: Int) {
        let updates = try await getUpdates(botToken: botToken, offset: offset, timeout: 30)
        let nextOffset = updates.map { $0.updateId + 1 }.max() ?? offset
        for update in updates {
            if let text = update.message?.text,
               update.message?.chat.id.description == chatId,
               text.lowercased().contains("paired") || text.contains("✓") {
                return (confirmed: true, nextOffset: nextOffset)
            }
        }
        return (confirmed: false, nextOffset: nextOffset)
    }

    // MARK: - Private

    private func getUpdates(botToken: String, offset: Int, timeout: Int) async throws -> [TGUpdate] {
        var components = URLComponents(string: "\(base)/bot\(botToken)/getUpdates")!
        components.queryItems = [
            .init(name: "offset", value: "\(offset)"),
            .init(name: "timeout", value: "\(timeout)"),
            .init(name: "allowed_updates", value: "[\"message\"]"),
        ]
        let (data, response) = try await session.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TelegramError.httpError
        }
        let envelope = try JSONDecoder().decode(TGResponse<[TGUpdate]>.self, from: data)
        guard envelope.ok else { throw TelegramError.apiError(envelope.description ?? "unknown") }
        return envelope.result ?? []
    }

    private func extractPairingCode(from text: String) -> String? {
        // Format sent by the plugin: "PAIRING_CODE: OAK-RIVER-7142"
        // Also accept the human-readable "OAK · RIVER · 7142" format.
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("PAIRING_CODE:") {
                return line.replacingOccurrences(of: "PAIRING_CODE:", with: "").trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
}

// MARK: - Telegram API response models

private struct TGResponse<T: Decodable>: Decodable {
    let ok: Bool
    let result: T?
    let description: String?
}

struct TGUpdate: Decodable {
    let updateId: Int
    let message: TGMessage?
    enum CodingKeys: String, CodingKey {
        case updateId = "update_id"
        case message
    }
}

struct TGMessage: Decodable {
    let messageId: Int
    let chat: TGChat
    let text: String?
    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case chat, text
    }
}

struct TGChat: Decodable {
    let id: Int64
}

enum TelegramError: LocalizedError {
    case httpError
    case apiError(String)
    case noPairingCodeReceived
    case timeout

    var errorDescription: String? {
        switch self {
        case .httpError: "Network error — check your connection."
        case .apiError(let msg): "Telegram API error: \(msg)"
        case .noPairingCodeReceived: "No pairing code received. Make sure your home computer is running Claude Code with the Telegram plugin."
        case .timeout: "Timed out waiting for confirmation."
        }
    }
}
