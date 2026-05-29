import Foundation

/// HTTP client for the Supabase-backed relay infrastructure.
///
/// Responsibilities:
/// - POST `/functions/v1/pair`  — exchange pairing code for (channelId, authToken)
///
/// Realtime Broadcast (captures + replies) is handled by ``RelayCaptureService``.
final class RelayChannelService {
    static let shared = RelayChannelService()
    private init() {}

    /// Supabase project base URL. Read from Info.plist key `SUP_URL`.
    /// Falls back to a placeholder so the app still builds without a config file.
    static let supabaseURL: URL = {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "SUP_URL") as? String,
           let url = URL(string: raw),
           !raw.hasPrefix("$(") {
            return url
        }
        return URL(string: "https://your-project.supabase.co")!
    }()

    private let session = URLSession.shared

    // MARK: - Pairing

    func pair(code: String) async throws -> (channelId: String, authToken: String) {
        let url = RelayChannelService.supabaseURL
            .appending(path: "/functions/v1/pair")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["code": code])

        let (data, response) = try await session.data(for: req)
        try validate(response: response, data: data, allow202: false)

        let body = try JSONDecoder().decode(PairResponse.self, from: data)
        return (channelId: body.channelId, authToken: body.token)
    }

    // MARK: - Private

    private func validate(response: URLResponse, data: Data, allow202: Bool) throws {
        guard let http = response as? HTTPURLResponse else {
            throw ChannelError.networkError(URLError(.badServerResponse))
        }
        switch http.statusCode {
        case 200, 201: return
        case 202 where allow202: return
        case 401: throw ChannelError.unauthorized
        case 404:
            let msg = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error ?? ""
            if msg.contains("expired") { throw ChannelError.codeExpired }
            throw ChannelError.invalidCode
        default:
            let msg = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error
                ?? String(data: data, encoding: .utf8)
                ?? "HTTP \(http.statusCode)"
            if msg.contains("invalid") || msg.contains("expired") {
                throw ChannelError.invalidCode
            }
            throw ChannelError.serverError(http.statusCode, msg)
        }
    }
}

// MARK: - Codable models

private struct PairResponse: Decodable {
    let token: String
    let channelId: String
}

private struct ErrorBody: Decodable {
    let error: String
}

// MARK: - Errors

enum ChannelError: LocalizedError {
    case invalidCode
    case codeExpired
    case unauthorized
    case pluginOffline
    case serverError(Int, String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidCode:   "That pairing code didn't match. Check for typos."
        case .codeExpired:   "The pairing code has expired. Restart the relay plugin to get a new one."
        case .unauthorized:  "This device is no longer authorized. Re-pair in settings."
        case .pluginOffline: "The relay plugin isn't running on your Claude machine."
        case .serverError(let status, let msg): "Server error \(status): \(msg)"
        case .networkError(let e): e.localizedDescription
        }
    }
}
