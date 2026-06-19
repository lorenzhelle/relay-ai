import Foundation

// MARK: - Event types (mirrors relay-supabase/types.ts)

/// A voice capture ready to publish to the plugin via Supabase Realtime Broadcast.
private struct CapturePayload: Encodable {
    let type = "capture"
    let clientCaptureId: String
    let transcript: String
    let durationSeconds: Double
    let timestamp: String
    /// When false the agent should process silently without sending a spoken reply.
    let voiceReply: Bool
}

/// Events the iOS app can receive back from the plugin.
enum RelayEvent {
    /// Plugin acknowledged the capture (silent success).
    case ack(clientCaptureId: String)
    /// Plugin wants iOS to speak a message aloud (and display it).
    /// `clientCaptureId` is nil when the reply isn't tied to a specific capture.
    case speak(clientCaptureId: String?, text: String)
}

// MARK: - RelayCaptureService

/// Manages the live Supabase Realtime Broadcast WebSocket for sending captures
/// and receiving acks / spoken replies from the relay plugin.
///
/// Uses `URLSessionWebSocketTask` with Supabase's Phoenix WebSocket protocol —
/// no additional SDK dependency required.
@Observable
final class RelayCaptureService {
    static let shared = RelayCaptureService()
    private init() {}

    // MARK: - Observable state

    private(set) var isConnected = false

    // MARK: - Private state

    private var webSocketTask: URLSessionWebSocketTask?
    private var channelId: String?
    private var anonKey: String?
    /// All registered event observers, keyed by an opaque token.
    private var eventHandlers: [UUID: (RelayEvent) -> Void] = [:]

    private let urlSession = URLSession(configuration: .default)

    // MARK: - Public API

    /// Start the Realtime connection and subscribe to the plugin→iOS channel.
    ///
    /// - Parameters:
    ///   - channelId: The channel UUID from the pairing response.
    ///   - supabaseURL: Base URL of the Supabase project.
    ///   - anonKey: Supabase publishable/anon key (public, safe on client).
    ///   - onEvent: Called on the main actor when an ack or speak event arrives.
    ///              Returns an opaque token that can be passed to `removeHandler(_:)`.
    @MainActor
    @discardableResult
    func startListening(
        channelId: String,
        supabaseURL: URL,
        anonKey: String,
        onEvent: @escaping @MainActor (RelayEvent) -> Void
    ) -> UUID {
        self.channelId = channelId
        self.anonKey = anonKey
        let token = addHandler(onEvent)
        if webSocketTask == nil {
            openConnection(supabaseURL: supabaseURL, anonKey: anonKey, channelId: channelId)
        }
        return token
    }

    /// Register an additional event observer on an already-running connection.
    ///
    /// - Returns: An opaque token to pass to `removeHandler(_:)` when done.
    @MainActor
    @discardableResult
    func addHandler(_ handler: @escaping @MainActor (RelayEvent) -> Void) -> UUID {
        let token = UUID()
        eventHandlers[token] = handler
        return token
    }

    /// Remove a previously registered event observer.
    @MainActor
    func removeHandler(_ token: UUID) {
        eventHandlers.removeValue(forKey: token)
    }

    /// Stop the WebSocket and clean up all handlers.
    @MainActor
    func stopListening() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        channelId = nil
        anonKey = nil
        eventHandlers.removeAll()
    }

    /// Publish a capture over the ios→plugin broadcast channel.
    @MainActor
    func sendCapture(
        transcript: String,
        clientCaptureId: UUID,
        durationSeconds: Double,
        timestamp: Date,
        voiceReply: Bool
    ) {
        guard let channelId else { return }

        let payload = CapturePayload(
            clientCaptureId: clientCaptureId.uuidString,
            transcript: transcript,
            durationSeconds: durationSeconds,
            timestamp: ISO8601DateFormatter().string(from: timestamp),
            voiceReply: voiceReply
        )

        sendBroadcast(
            event: "message",
            payload: payload,
            on: "relay:\(channelId):ios-to-plugin"
        )
    }

    // MARK: - WebSocket lifecycle

    @MainActor
    private func openConnection(supabaseURL: URL, anonKey: String, channelId: String) {
        var components = URLComponents(
            url: supabaseURL.appending(path: "/realtime/v1/websocket"),
            resolvingAgainstBaseURL: false
        )!
        components.scheme = supabaseURL.scheme == "https" ? "wss" : "ws"
        components.queryItems = [
            URLQueryItem(name: "apikey", value: anonKey),
            URLQueryItem(name: "vsn", value: "1.0.0"),
        ]
        guard let wsURL = components.url else { return }

        var request = URLRequest(url: wsURL)
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        let task = urlSession.webSocketTask(with: request)
        webSocketTask = task
        task.resume()

        // Join both channels (Phoenix protocol requires joining before sending or receiving)
        let replyChannel = "relay:\(channelId):plugin-to-ios"
        let joinReply: [String: Any] = [
            "topic": "realtime:\(replyChannel)",
            "event": "phx_join",
            "payload": ["config": ["broadcast": ["self": false]]],
            "ref": "1",
        ]
        sendRaw(json: joinReply)

        // Must join the send channel too — server drops broadcasts from non-members
        let sendChannel = "relay:\(channelId):ios-to-plugin"
        let joinSend: [String: Any] = [
            "topic": "realtime:\(sendChannel)",
            "event": "phx_join",
            "payload": ["config": ["broadcast": ["self": false]]],
            "ref": "2",
        ]
        sendRaw(json: joinSend)

        isConnected = true
        receiveLoop()
    }

    private func receiveLoop() {
        guard let task = webSocketTask else { return }
        task.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let msg):
                if case .string(let text) = msg {
                    Task { @MainActor in self.handleIncoming(text) }
                }
                Task { @MainActor in self.receiveLoop() }
            case .failure:
                Task { @MainActor in self.isConnected = false }
            }
        }
    }

    @MainActor
    private func handleIncoming(_ text: String) {
        guard
            let data = text.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let event = json["event"] as? String,
            event == "broadcast",
            // Supabase JS SDK wraps broadcasts in a Phoenix envelope:
            // payload = { type:"broadcast", event:"message", payload: <actual data> }
            // so we need to unwrap one extra level.
            let outerPayload = json["payload"] as? [String: Any],
            let payload = outerPayload["payload"] as? [String: Any],
            let type_ = payload["type"] as? String
        else { return }

        let relayEvent: RelayEvent
        switch type_ {
        case "ack":
            guard let id = payload["clientCaptureId"] as? String else { return }
            relayEvent = .ack(clientCaptureId: id)
        case "speak":
            guard let text_ = payload["text"] as? String else { return }
            // clientCaptureId is optional: the agent includes it when the reply
            // answers a specific capture, but a bare reply is still valid.
            let id = payload["clientCaptureId"] as? String
            relayEvent = .speak(clientCaptureId: id, text: text_)
        default:
            return
        }
        for handler in eventHandlers.values { handler(relayEvent) }
    }

    // MARK: - Helpers

    @MainActor
    private func sendBroadcast(event: String, payload: some Encodable, on channel: String) {
        guard
            let payloadData = try? JSONEncoder().encode(payload),
            let payloadJSON = try? JSONSerialization.jsonObject(with: payloadData)
        else { return }

        let msg: [String: Any] = [
            "topic": "realtime:\(channel)",
            "event": "broadcast",
            "payload": [
                "type": "broadcast",
                "event": event,
                "payload": payloadJSON,
            ],
            "ref": NSNull(),
        ]
        sendRaw(json: msg)
    }

    private func sendRaw(json: [String: Any]) {
        guard
            let data = try? JSONSerialization.data(withJSONObject: json),
            let str = String(data: data, encoding: .utf8)
        else { return }
        webSocketTask?.send(.string(str)) { _ in }
    }
}
