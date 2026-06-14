import Foundation

enum CaptureStatus {
    case queued, sent, failed
}

struct Capture: Identifiable {
    let id: UUID
    let timestamp: Date
    var transcript: String
    var status: CaptureStatus
    var durationSeconds: Double
    /// The agent's spoken reply, once it arrives. Displayed beneath the capture.
    var reply: String? = nil

    var shortId: String {
        id.uuidString.prefix(5).lowercased()
    }
}
