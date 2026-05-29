import Foundation
import Security

struct ChannelCredentials {
    let channelId: String
    let authToken: String
}

struct PairingResult: Hashable {
    let channelId: String
    let authToken: String
}

final class KeychainStore {
    static let shared = KeychainStore()
    private init() {}

    private let service = "lorenzhelle.relay"

    func save(channelId: String) throws {
        try save(key: "channelId", value: channelId)
    }

    func save(authToken: String) throws {
        try save(key: "authToken", value: authToken)
    }

    func loadChannelCredentials() throws -> ChannelCredentials {
        let channelId = try load(key: "channelId")
        let authToken = try load(key: "authToken")
        return ChannelCredentials(channelId: channelId, authToken: authToken)
    }

    func clearAll() {
        for key in ["channelId", "authToken"] {
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
