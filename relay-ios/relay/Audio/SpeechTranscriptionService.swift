import Foundation
import Speech
import AVFoundation

/// On-device speech-to-text using Apple's `SpeechAnalyzer` / `SpeechTranscriber`
/// (Speech framework, iOS 26). Fully local — no audio leaves the device, and no
/// network speech recognition is used.
///
/// Replaces the old SFSpeechRecognizer-based path. The transcriber needs a
/// locale-specific model; we install it on first use via `AssetInventory` and
/// keep it reserved so subsequent captures are fast.
@MainActor
@Observable
final class SpeechTranscriptionService {
    /// True once the on-device model for `resolvedLocale` is installed & reserved.
    private(set) var isReady: Bool = false

    private var resolvedLocale: Locale?

    enum TranscriptionError: Error {
        case localeNotSupported
        case noResult
    }

    // MARK: - Model preparation

    /// Resolve the locale, download the on-device model if needed, and reserve it.
    /// Safe to call repeatedly — it no-ops once ready. Called as a pre-warm while
    /// the user is still speaking so transcription starts instantly on stop.
    func prepareIfNeeded() async throws {
        guard !isReady else { return }

        let locale = try await resolveLocale()
        let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)

        // Download the locale's model the first time it's used on this device.
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await request.downloadAndInstall()
        }
        // Keep the model resident so later captures don't re-download.
        _ = try? await AssetInventory.reserve(locale: locale)

        resolvedLocale = locale
        isReady = true
    }

    // MARK: - Transcription

    /// Transcribe a recorded audio file fully on-device. Returns the recognized text.
    func transcribe(url: URL) async throws -> String {
        try await prepareIfNeeded()
        guard let locale = resolvedLocale else { throw TranscriptionError.localeNotSupported }

        let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)
        let audioFile = try AVAudioFile(forReading: url)

        // Drain finalized results concurrently with analysis. With
        // finishAfterFile, the analyzer finalizes once the file is consumed,
        // which terminates the results stream and lets the collector return.
        let collector = Task { () throws -> AttributedString in
            var text = AttributedString()
            for try await result in transcriber.results {
                text.append(result.text)
            }
            return text
        }

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        try await analyzer.start(inputAudioFile: audioFile, finishAfterFile: true)

        let text = try await collector.value
        return String(text.characters)
    }

    // MARK: - Private

    /// Pick a supported locale equivalent to the user's current locale, falling
    /// back to en-US, so transcription works even on locales without a model.
    private func resolveLocale() async throws -> Locale {
        if let match = await SpeechTranscriber.supportedLocale(equivalentTo: Locale.current) {
            return match
        }
        if let english = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: "en-US")) {
            return english
        }
        throw TranscriptionError.localeNotSupported
    }
}
