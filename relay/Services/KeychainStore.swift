import Foundation
import Security

struct RelayCredentials {
    let botToken: String
    let chatId: String
    let channel: String
}

struct PairingResult: Hashable {
    let botUsername: String
    let botToken: String
    let chatId: String
    let channel: String
    let roundTripMs: Int?
    let mcps: [String]
}

final class KeychainStore {
    static let shared = KeychainStore()
    private init() {}

    private let service = "lorenzhelle.relay"

    func save(botToken: String) throws {
        try save(key: "botToken", value: botToken)
    }

    func save(chatId: String) throws {
        try save(key: "chatId", value: chatId)
    }

    func save(channel: String) throws {
        try save(key: "channel", value: channel)
    }

    func loadCredentials() throws -> RelayCredentials {
        let token   = try load(key: "botToken")
        let chatId  = try load(key: "chatId")
        let channel = (try? load(key: "channel")) ?? ""
        return RelayCredentials(botToken: token, chatId: chatId, channel: channel)
    }

    func clearAll() {
        for key in ["botToken", "chatId", "channel"] {
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: key,
            ]
            SecItemDelete(query as CFDictionary)
        }
    }

    // MARK: - Private

    private func save(key: String, value: String) throws {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
        ]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData] = data
        let status = SecItemAdd(attrs as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    private func load(key: String) throws -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.notFound
        }
        return string
    }
}

enum KeychainError: Error {
    case notFound
    case saveFailed(OSStatus)
}
