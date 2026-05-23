import Foundation
import UIKit

@Observable
final class PairingCodeViewModel {
    let botToken: String
    var chatId: String

    var pairingCode: String
    var secondsRemaining: Int = 90
    var isPolling: Bool = true
    var isExpired: Bool = false
    var errorMessage: String? = nil

    private var timerTask: Task<Void, Never>?
    private var pollingTask: Task<Void, Never>?
    private let pairing = PairingService.shared

    var displayCode: String {
        pairingCode.isEmpty ? "— — —" : pairingCode.uppercased().replacingOccurrences(of: "-", with: " · ")
    }

    var clipboardCommand: String {
        "/telegram:access pair \(pairingCode.lowercased())"
    }

    init(botToken: String, chatId: String, initialCode: String) {
        self.botToken = botToken
        self.chatId = chatId
        self.pairingCode = initialCode
    }

    func startPolling(onConfirmed: @escaping (PairingResult) -> Void) {
        isExpired = false
        isPolling = true
        secondsRemaining = 90

        timerTask = Task {
            for remaining in stride(from: 90, through: 0, by: -1) {
                if Task.isCancelled { break }
                secondsRemaining = remaining
                try? await Task.sleep(for: .seconds(1))
            }
            if !Task.isCancelled {
                isExpired = true
                isPolling = false
            }
        }

        pollingTask = Task {
            do {
                let result = try await pairing.waitForConfirmation(
                    botToken: botToken,
                    chatId: chatId,
                    pairingCode: pairingCode
                )
                if !Task.isCancelled {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onConfirmed(result)
                }
            } catch is CancellationError {
                // expected on view disappear
            } catch {
                errorMessage = error.localizedDescription
                isPolling = false
            }
        }
    }

    func requestNewCode(onSuccess: @escaping (String) -> Void) {
        cancelTasks()
        isExpired = false
        isPolling = true
        errorMessage = nil

        Task {
            do {
                let (_, newChatId, code) = try await pairing.requestPairingCode(botInput: botToken)
                pairingCode = code
                chatId = newChatId
                onSuccess(code)
            } catch {
                errorMessage = error.localizedDescription
                isPolling = false
            }
        }
    }

    func copyCommand() {
        UIPasteboard.general.string = clipboardCommand
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func cancelTasks() {
        timerTask?.cancel()
        pollingTask?.cancel()
        timerTask = nil
        pollingTask = nil
    }
}
