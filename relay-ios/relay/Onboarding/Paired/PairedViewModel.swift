import Foundation

@Observable
final class PairedViewModel {
    let result: PairingResult

    var whisperProgress: Double = 0
    var whisperReceived: Int = 0
    let whisperTotal: Int = 152

    private var downloadTask: Task<Void, Never>?

    init(result: PairingResult) {
        self.result = result
    }

    func startWhisperDownload() {
        // Simulated progress — replace with actual WhisperKit download when integrated.
        downloadTask = Task {
            for mb in stride(from: 0, through: whisperTotal, by: 1) {
                if Task.isCancelled { break }
                whisperReceived = mb
                whisperProgress = Double(mb) / Double(whisperTotal)
                try? await Task.sleep(for: .milliseconds(80))
            }
        }
    }

    func cancel() {
        downloadTask?.cancel()
    }
}
