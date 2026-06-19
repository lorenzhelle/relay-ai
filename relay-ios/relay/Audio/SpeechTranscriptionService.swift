import Foundation
import Speech
import AVFoundation

/// On-device speech-to-text using Apple's `SpeechAnalyzer` / `SpeechTranscriber`
/// (Speech framework, iOS 26). Fully local — no audio leaves the device.
///
/// Architecture (streaming, per WWDC 2025):
/// - `prepareIfNeeded()` installs the on-device model once and queries the best audio format.
/// - `startSession()` opens an `AsyncStream<AnalyzerInput>` and starts the analyser.
/// - `streamBuffer()` converts + yields each PCM buffer from the mic tap.
/// - `finishSession()` finalises the analyser and returns the collected transcript.
///
/// `liveTranscript` is updated in real time as volatile and final results arrive, so
/// the recording UI can display text while the user is still speaking.
@MainActor
@Observable
final class SpeechTranscriptionService {

    // MARK: - Model status

    enum ModelStatus: Equatable {
        case unknown
        case checking
        case available
        case unavailable(String)
    }

    private(set) var modelStatus: ModelStatus = .unknown

    // MARK: - Live transcript

    /// Updated continuously during a session: finalized text + current volatile segment.
    private(set) var liveTranscript: String = ""

    // MARK: - Internal

    /// The format `SpeechAnalyzer` prefers.  Set by `prepareIfNeeded()`; used by
    /// `streamBuffer()` to convert mic buffers before yielding them.
    private(set) var analyzerFormat: AVAudioFormat?

    private(set) var resolvedLocale: Locale?
    private var isReady: Bool = false

    /// E.g. "Deutsch" or "English" — available once `prepareIfNeeded()` succeeds.
    var resolvedLanguageName: String? {
        guard let locale = resolvedLocale else { return nil }
        // Show the language name in that language itself (e.g. "Deutsch", not "German").
        return locale.localizedString(forLanguageCode: locale.language.languageCode?.identifier ?? "")
            ?? locale.identifier
    }

    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var recognizerTask: Task<AttributedString, Error>?

    private let converter = BufferConverter()

    enum TranscriptionError: Error {
        case localeNotSupported
    }

    // MARK: - Model preparation

    /// Resolve locale, download the on-device model if needed, reserve it, and
    /// query the preferred audio format.  No-ops once ready.
    func prepareIfNeeded() async throws {
        guard !isReady else { return }

        modelStatus = .checking
        do {
            let locale = try await resolveLocale()

            let probe = SpeechTranscriber(locale: locale, transcriptionOptions: [],
                                          reportingOptions: [], attributeOptions: [])

            if let request = try await AssetInventory.assetInstallationRequest(supporting: [probe]) {
                try await request.downloadAndInstall()
            }

            let reserved = await AssetInventory.reservedLocales
            if !reserved.contains(where: { $0.identifier(.bcp47) == locale.identifier(.bcp47) }) {
                try await AssetInventory.reserve(locale: locale)
            }

            analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [probe])
            resolvedLocale = locale
            isReady = true
            modelStatus = .available
        } catch {
            modelStatus = .unavailable(error.localizedDescription)
            throw error
        }
    }

    // MARK: - Session lifecycle

    /// Open a streaming transcription session.  Call after `prepareIfNeeded()` succeeds,
    /// before the first buffer arrives.
    func startSession() async throws {
        guard let locale = resolvedLocale else { throw TranscriptionError.localeNotSupported }

        liveTranscript = ""

        let txr = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: [])
        self.transcriber = txr

        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()
        self.inputContinuation = continuation

        // Drain results on the MainActor, updating liveTranscript as each chunk arrives.
        recognizerTask = Task { @MainActor in
            var finalized = AttributedString()
            for try await result in txr.results {
                if result.isFinal {
                    finalized.append(result.text)
                    liveTranscript = String(finalized.characters)
                } else {
                    // Volatile: show finalized prefix + current partial
                    liveTranscript = String(finalized.characters) + String(result.text.characters)
                }
            }
            return finalized
        }

        let anlz = SpeechAnalyzer(modules: [txr])
        self.analyzer = anlz
        try await anlz.start(inputSequence: stream)
    }

    /// Feed one audio buffer into the active session.  Converts to `analyzerFormat`
    /// if necessary.  No-op if no session is open or the model isn't ready.
    func streamBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let continuation = inputContinuation,
              let targetFormat = analyzerFormat else { return }
        let converted = (try? converter.convert(buffer, to: targetFormat)) ?? buffer
        continuation.yield(AnalyzerInput(buffer: converted))
    }

    /// Close the session, finalize the recogniser, and return the full transcript.
    /// Idempotent — safe to call even if `startSession()` was never reached.
    func finishSession() async throws -> String {
        guard let continuation = inputContinuation,
              let analyzer = analyzer,
              let recognizerTask = recognizerTask else {
            let last = liveTranscript
            cleanUpSession()
            return last
        }

        continuation.finish()
        try await analyzer.finalizeAndFinishThroughEndOfInput()
        let text = try await recognizerTask.value
        cleanUpSession()
        return String(text.characters)
    }

    /// Cancel without collecting results.
    func cancelSession() {
        inputContinuation?.finish()
        recognizerTask?.cancel()
        cleanUpSession()
    }

    // MARK: - Private

    private func cleanUpSession() {
        inputContinuation = nil
        analyzer = nil
        transcriber = nil
        recognizerTask = nil
        liveTranscript = ""
    }

    private func resolveLocale() async throws -> Locale {
        // Preference order: German → user's current locale → English fallback.
        let candidates: [Locale] = [
            Locale(identifier: "de-DE"),
            Locale.current,
            Locale(identifier: "en-US"),
        ]
        for candidate in candidates {
            if let match = await SpeechTranscriber.supportedLocale(equivalentTo: candidate) {
                return match
            }
        }
        throw TranscriptionError.localeNotSupported
    }
}
