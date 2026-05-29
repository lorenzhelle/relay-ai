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

    var shortId: String {
        id.uuidString.prefix(5).lowercased()
    }
}
