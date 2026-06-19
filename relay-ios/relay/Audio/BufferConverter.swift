@preconcurrency import AVFoundation
import Foundation

/// Resamples/reformats an `AVAudioPCMBuffer` to a target `AVAudioFormat`,
/// reusing a single `AVAudioConverter` as long as the output format stays the same.
final class BufferConverter {
    enum ConversionError: Error {
        case failedToCreateConverter
        case failedToAllocateOutputBuffer
        case conversionFailed(NSError?)
    }

    private var converter: AVAudioConverter?

    func convert(_ buffer: AVAudioPCMBuffer, to targetFormat: AVAudioFormat) throws -> AVAudioPCMBuffer {
        guard buffer.format != targetFormat else { return buffer }

        if converter == nil || converter?.outputFormat != targetFormat {
            converter = AVAudioConverter(from: buffer.format, to: targetFormat)
            // Avoid timestamp drift on the first few samples at the cost of slight quality.
            converter?.primeMethod = .none
        }
        guard let converter else { throw ConversionError.failedToCreateConverter }

        let ratio = converter.outputFormat.sampleRate / converter.inputFormat.sampleRate
        let capacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up))
        guard let output = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: capacity) else {
            throw ConversionError.failedToAllocateOutputBuffer
        }

        // The input block is called synchronously once per convert(); the `consumed`
        // flag prevents handing the buffer a second time if the converter asks again.
        var consumed = false
        var nsError: NSError?
        let status = converter.convert(to: output, error: &nsError) { _, inputStatus in
            guard !consumed else {
                inputStatus.pointee = .noDataNow
                return nil
            }
            consumed = true
            inputStatus.pointee = .haveData
            return buffer
        }

        if status == .error { throw ConversionError.conversionFailed(nsError) }
        return output
    }
}
