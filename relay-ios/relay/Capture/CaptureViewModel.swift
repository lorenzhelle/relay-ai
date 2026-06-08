import Foundation
import UIKit

enum CaptureFlowState {
    case idle
    case listening
    case recording(transcript: String)
    case transcribing
    case captured(Capture)
}

@MainActor
@Observable
final class CaptureViewModel {
    private(set) var state: CaptureFlowState = .idle
    private(set) var elapsedSeconds: Int = 0

    let recorder: AudioRecorder = AudioRecorder()
    let whisper: WhisperService
    let store: CaptureStore

    private var transcribeTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var recordingStartDate: Date?

    init(whisper: WhisperService, store: CaptureStore) {
        self.whisper = whisper
        self.store = store
        // Update capture status when the plugin acks a delivery.
        // No deregistration needed: CaptureViewModel is @State in AppCoordinatorView
        // and lives for the entire app session.
        RelayCaptureService.shared.addHandler { [weak store] event in
            guard case .ack(let captureId) = event,
                  let id = UUID(uuidString: captureId) else { return }
            store?.updateStatus(of: id, to: .sent)
        }
    }

    // MARK: - Start

    func startCapture() {
        guard case .idle = state else { return }
        state = .listening   // set synchronously to block re-entrant calls
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        transcribeTask = Task {
            do {
                try await recorder.start()
                recordingStartDate = Date()
                startTimer()
                // Pre-warm Whisper while user is speaking
                try? await whisper.loadIfNeeded()
            } catch {
                state = .idle
            }
        }
    }

    // MARK: - Stop (release gesture or tap-to-send)

    func stopCapture() {
        switch state {
        case .listening, .recording:
            // Require at least 0.5s of recording before committing
            let duration = recordingStartDate.map { Date().timeIntervalSince($0) } ?? 0
            if duration < 0.5 { cancelCapture() } else { commitStop() }
        default:
            break
        }
    }

    // MARK: - Cancel

    func cancelCapture() {
        transcribeTask?.cancel()
        timerTask?.cancel()
        recorder.cancel()
        state = .idle
        elapsedSeconds = 0
    }

    // MARK: - Confirm (called from AckView after 2s or tap-to-keep)

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

    private func sendCapture(_ capture: Capture) async {
        RelayCaptureService.shared.sendCapture(
            transcript: capture.transcript,
            clientCaptureId: capture.id,
            durationSeconds: capture.durationSeconds,
            timestamp: capture.timestamp
        )
    }

    func dismissAck() {
        guard case .captured(let capture) = state else { return }
        store.add(capture)
        state = .idle
        elapsedSeconds = 0
    }

    // MARK: - Called from listening state when speech starts

    func speechDetected() {
        guard case .listening = state else { return }
        state = .recording(transcript: "")
    }

    // MARK: - Private

    private func commitStop() {
        timerTask?.cancel()
        let duration = recordingStartDate.map { Date().timeIntervalSince($0) } ?? 0
        state = .transcribing

        let currentDuration = duration
        transcribeTask = Task {
            let url = recorder.stop()

            var transcript = ""
            if let url {
                transcript = (try? await whisper.transcribe(url: url)) ?? ""
                try? FileManager.default.removeItem(at: url)
            }

            let capture = Capture(
                id: UUID(),
                timestamp: Date(),
                transcript: transcript.isEmpty ? "(no speech detected)" : transcript,
                status: .queued,
                durationSeconds: currentDuration
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
                // Auto-transition listening → recording if no speech detected after 0.5s
                // (actual speech detection is via audioLevel threshold in the view)
            }
        }
    }

    // Called from ListeningView waveform to promote to recording state
    func promoteToRecordingIfListening() {
        if case .listening = state, recorder.audioLevel > 0.05 {
            state = .recording(transcript: "…")
        }
    }
}
