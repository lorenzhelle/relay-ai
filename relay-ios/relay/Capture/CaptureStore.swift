import Foundation

@MainActor
@Observable
final class CaptureStore {
    private(set) var captures: [Capture] = []

    func add(_ capture: Capture) {
        captures.insert(capture, at: 0)
    }

    func updateStatus(of id: UUID, to status: CaptureStatus) {
        if let idx = captures.firstIndex(where: { $0.id == id }) {
            captures[idx].status = status
        }
    }

    /// Attach the agent's reply to a capture. When `id` is nil or doesn't match a
    /// known capture, the reply is attached to the most recent capture (the one
    /// the agent is answering, since transcripts are processed in order).
    func setReply(_ text: String, for id: UUID?) {
        let idx: Int? = {
            if let id, let match = captures.firstIndex(where: { $0.id == id }) {
                return match
            }
            return captures.indices.first   // captures are newest-first
        }()
        guard let idx else { return }
        captures[idx].reply = text
        captures[idx].status = .sent
    }
}
