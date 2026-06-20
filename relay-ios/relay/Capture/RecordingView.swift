import SwiftUI

struct RecordingView: View {
    @Environment(CaptureViewModel.self) private var vm
    @State private var caretVisible: Bool = true

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.relayBg.ignoresSafeArea()

            VStack(spacing: 0) {
                RelayHeader(status: .recording, detail: "recording · \(timerLabel(vm.elapsedSeconds))")

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        transcriptLabel

                        HStack(alignment: .bottom, spacing: 0) {
                            transcriptText
                                .animation(.easeOut(duration: 0.1), value: vm.speech.liveTranscript)

                            // Blinking caret
                            Rectangle()
                                .fill(Color.relayAmber)
                                .frame(width: 2, height: 24)
                                .opacity(caretVisible ? 1 : 0)
                                .padding(.bottom, 2)
                                .padding(.leading, 2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, RelaySpacing.screenHWide)
                    .padding(.bottom, 220)
                }
                .scrollIndicators(.hidden)
                .defaultScrollAnchor(.bottom)
            }

            VStack(spacing: 14) {
                WaveformView(level: max(0.2, vm.recorder.audioLevel), tint: .relayAmber, active: true)

                Button {
                    vm.stopCapture()
                } label: {
                    HStack {
                        Spacer()
                        Text("release to send")
                            .font(.relaySans(size: 16, weight: .medium))
                            .foregroundStyle(Color.relayOnInk)
                        Spacer()
                    }
                    .frame(height: RelaySpacing.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: RelaySpacing.buttonRadius)
                            .fill(Color.relayAmber)
                            .shadow(color: .relayAmber.opacity(0.5), radius: 16, y: 8)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, RelaySpacing.screenH)
            .padding(.bottom, RelaySpacing.ctaBottom)
        }
        .task {
            while true {
                try? await Task.sleep(for: .milliseconds(500))
                caretVisible.toggle()
            }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var transcriptLabel: some View {
        switch vm.speech.modelStatus {
        case .unavailable:
            Label("speech model unavailable — no transcript", systemImage: "waveform.slash")
                .font(.jetbrainsMono(size: 10))
                .foregroundStyle(Color.relayAmber)
                .tracking(0.8)
                .textCase(.uppercase)
        default:
            let lang = vm.speech.resolvedLanguageName?.lowercased() ?? "on-device"
            Text("transcript · \(lang)")
                .font(.jetbrainsMono(size: 10))
                .foregroundStyle(Color.relayFaint)
                .tracking(1.2)
                .textCase(.uppercase)
        }
    }

    @ViewBuilder
    private var transcriptText: some View {
        switch vm.speech.modelStatus {
        case .unavailable:
            Text("transcription unavailable")
                .font(.newsreader(size: 22, italic: true))
                .foregroundStyle(Color.relayFaint)
                .tracking(-0.2)
                .lineSpacing(6)
        default:
            let finalized = vm.speech.finalizedText
            let volatile = vm.speech.volatileText
            if finalized.isEmpty && volatile.isEmpty {
                Text("…")
                    .font(.newsreader(size: 22))
                    .foregroundStyle(Color.relayInk)
                    .tracking(-0.2)
                    .lineSpacing(6)
            } else {
                // Volatile text renders at lower opacity so refinements read as polish, not flicker.
                (
                    Text(finalized).foregroundStyle(Color.relayInk) +
                    Text(volatile).foregroundStyle(Color.relayInk.opacity(0.45))
                )
                .font(.newsreader(size: 22))
                .tracking(-0.2)
                .lineSpacing(6)
            }
        }
    }

    private func timerLabel(_ seconds: Int) -> String {
        String(format: "0:%02d", seconds)
    }
}
