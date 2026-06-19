import Foundation
import UIKit

enum CaptureFlowState {
    case idle
    case listening
    case recording
    case transcribing
    case captured(Capture)
}

@MainActor
@Observable
final class CaptureViewModel {
    private(set) var state: CaptureFlowState = .idle
    private(set) var elapsedSeconds: Int = 0

    let recorder: AudioRecorder = AudioRecorder()
    let speech: SpeechTranscriptionService
    let store: CaptureStore
    var settings: RelaySettings?

    private var captureTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var recordingStartDate: Date?

    init(speech: SpeechTranscriptionService, store: CaptureStore) {
        self.speech = speech
        self.store = store
        RelayCaptureService.shared.addHandler { [weak store] event in
            switch event {
            case .ack(let captureId):
                guard let id = UUID(uuidString: captureId) else { return }
                store?.updateStatus(of: id, to: .sent)
            case .speak(let captureId, let text), .text(let captureId, let text):
                store?.setReply(text, for: captureId.flatMap(UUID.init))
            }
        }
    }

    // MARK: - Start

    func startCapture() {
        guard case .idle = state else { return }
        state = .listening
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        captureTask = Task {
            do {
                // Prepare model and start session concurrently with mic start so the
                // first buffer has somewhere to go by the time the engine fires up.
                async let _ = speech.prepareIfNeeded()
                try await speech.startSession()
                try await recorder.start(speechService: speech)
                recordingStartDate = Date()
                startTimer()
            } catch {
                speech.cancelSession()
                state = .idle
            }
        }
    }

    // MARK: - Stop

    func stopCapture() {
        switch state {
        case .listening, .recording:
            let duration = recordingStartDate.map { Date().timeIntervalSince($0) } ?? 0
            if duration < 0.5 { cancelCapture() } else { commitStop() }
        default:
            break
        }
    }

    // MARK: - Cancel

    func cancelCapture() {
        captureTask?.cancel()
        timerTask?.cancel()
        recorder.cancel()
        speech.cancelSession()
        state = .idle
        elapsedSeconds = 0
    }

    // MARK: - Confirm

    func confirmCapture() {
        guard case .captured(let capture) = state else { return }
        store.add(capture)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            state = .idle
            elapsedSeconds = 0
        }
        Task { await sendCapture(capture) }
    }

    func dismissAck() {
        guard case .captured(let capture) = state else { return }
        store.add(capture)
        state = .idle
        elapsedSeconds = 0
    }

    // MARK: - Called from listening view when audio level crosses threshold

    func promoteToRecordingIfListening() {
        if case .listening = state, recorder.audioLevel > 0.05 {
            state = .recording
        }
    }

    // MARK: - Private

    private func sendCapture(_ capture: Capture) async {
        RelayCaptureService.shared.sendCapture(
            transcript: capture.transcript,
            clientCaptureId: capture.id,
            durationSeconds: capture.durationSeconds,
            timestamp: capture.timestamp,
            voiceReply: settings?.voiceMode ?? true
        )
    }

    private func commitStop() {
        timerTask?.cancel()
        let duration = recordingStartDate.map { Date().timeIntervalSince($0) } ?? 0
        state = .transcribing

        captureTask = Task {
            _ = recorder.stop()
            let transcript = (try? await speech.finishSession()) ?? ""
            let capture = Capture(
                id: UUID(),
                timestamp: Date(),
                transcript: transcript.isEmpty ? "(no speech detected)" : transcript,
                status: .queued,
                durationSeconds: duration
            )
            state = .captured(capture)
        }
    }

    private func startTimer() {
        elapsedSeconds = 0
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { break }
                elapsedSeconds += 1
            }
        }
    }
}
