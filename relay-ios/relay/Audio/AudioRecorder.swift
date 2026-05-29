import Foundation
import AVFoundation

@MainActor
@Observable
final class AudioRecorder {
    private(set) var isRecording: Bool = false
    private(set) var audioLevel: Float = 0   // 0–1, normalized for waveform

    private var engine = AVAudioEngine()
    private var outputURL: URL?
    private var audioFile: AVAudioFile?
    private var levelTimer: Timer?

    // MARK: - Start

    func start() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        outputURL = url

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
        let file = audioFile!

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            try? file.write(from: buffer)
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<frameLength { sum += channelData[i] * channelData[i] }
            let rms = sqrtf(sum / Float(frameLength))
            let db = 20 * log10f(max(rms, 1e-6))
            let normalized = Float(max(0, min(1, (db + 60) / 60)))
            Task { @MainActor [weak self] in self?.audioLevel = normalized }
        }

        engine.prepare()
        try engine.start()
        isRecording = true
    }

    // MARK: - Stop

    func stop() -> URL? {
        teardown()
        return outputURL
    }

    // MARK: - Cancel

    func cancel() {
        let url = outputURL
        teardown()
        if let url { try? FileManager.default.removeItem(at: url) }
        outputURL = nil
    }

    // MARK: - Private

    private func teardown() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        audioFile = nil
        isRecording = false
        audioLevel = 0
        try? AVAudioSession.sharedInstance().setActive(false)
    }

}
