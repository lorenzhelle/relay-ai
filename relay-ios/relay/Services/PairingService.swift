import Foundation

final class PairingService {
    static let shared = PairingService()
    private init() {}

    private let channel = RelayChannelService.shared
    private let keychain = KeychainStore.shared

    func pair(code: String) async throws -> PairingResult {
        let (channelId, authToken) = try await channel.pair(code: code)
        try keychain.save(channelId: channelId)
        try keychain.save(authToken: authToken)
        return PairingResult(channelId: channelId, authToken: authToken)
    }
}
