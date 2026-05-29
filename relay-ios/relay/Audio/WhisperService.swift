import Foundation
import Speech

@MainActor
@Observable
final class WhisperService {
    private(set) var isLoaded: Bool = false

    func loadIfNeeded() async throws {
        guard !isLoaded else { return }
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard status == .authorized else { throw TranscriptionError.notAuthorized }
        isLoaded = true
    }

    func transcribe(url: URL) async throws -> String {
        try await loadIfNeeded()

        let recognizer = SFSpeechRecognizer(locale: Locale.current)
            ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!

        guard recognizer.isAvailable else { throw TranscriptionError.unavailable }
        recognizer.supportsOnDeviceRecognition = true

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.requiresOnDeviceRecognition = false
        request.shouldReportPartialResults = false

        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result, result.isFinal else { return }
                continuation.resume(returning: result.bestTranscription.formattedString)
            }
        }
    }

    enum TranscriptionError: Error {
        case notAuthorized, unavailable
    }
}
