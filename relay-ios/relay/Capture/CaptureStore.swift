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
}
