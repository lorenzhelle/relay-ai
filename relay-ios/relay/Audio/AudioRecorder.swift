import Foundation
import AVFoundation

@MainActor
@Observable
final class AudioRecorder {
    private(set) var isRecording: Bool = false
    private(set) var audioLevel: Float = 0   // 0–1, normalised for waveform

    private var engine = AVAudioEngine()
    private var outputURL: URL?
    private var audioFile: AVAudioFile?

    // MARK: - Start

    /// Begin recording.  Buffers are forwarded to `speechService` in real time so
    /// `SpeechAnalyzer` can transcribe while the user is still speaking.
    func start(speechService: SpeechTranscriptionService) async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        outputURL = url

        let inputNode = engine.inputNode
        let nativeFormat = inputNode.outputFormat(forBus: 0)

        audioFile = try AVAudioFile(forWriting: url, settings: nativeFormat.settings)
        let file = audioFile!

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nativeFormat) { [weak self] buffer, _ in
            // Write to disk for debugging / potential fallback.
            try? file.write(from: buffer)

            // Compute normalised level for waveform animation.
            if let channelData = buffer.floatChannelData?[0] {
                let frameLength = Int(buffer.frameLength)
                var sum: Float = 0
                for i in 0..<frameLength { sum += channelData[i] * channelData[i] }
                let rms = sqrtf(sum / Float(frameLength))
                let db = 20 * log10f(max(rms, 1e-6))
                let normalized = Float(max(0, min(1, (db + 60) / 60)))
                Task { @MainActor [weak self] in self?.audioLevel = normalized }
            }

            // Forward to SpeechAnalyzer on the MainActor.
            Task { @MainActor in speechService.streamBuffer(buffer) }
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
