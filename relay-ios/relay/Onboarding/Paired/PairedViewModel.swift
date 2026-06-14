import Foundation

@Observable
final class PairedViewModel {
    let result: PairingResult

    var modelProgress: Double = 0
    var modelReceived: Int = 0
    let modelTotal: Int = 152

    private var downloadTask: Task<Void, Never>?

    init(result: PairingResult) {
        self.result = result
    }

    func startModelDownload() {
        // Simulated progress — the real on-device speech model is fetched lazily
        // by SpeechTranscriptionService via AssetInventory on first capture.
        downloadTask = Task {
            for mb in stride(from: 0, through: modelTotal, by: 1) {
                if Task.isCancelled { break }
                modelReceived = mb
                modelProgress = Double(mb) / Double(modelTotal)
                try? await Task.sleep(for: .milliseconds(80))
            }
        }
    }

    func cancel() {
        downloadTask?.cancel()
    }
}
