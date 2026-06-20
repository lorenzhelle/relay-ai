import SwiftUI

struct ListeningView: View {
    @Environment(CaptureViewModel.self) private var vm
    @Environment(RelaySettings.self) private var settings
    @State private var pulse: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.relayBg.ignoresSafeArea()

            VStack(spacing: 0) {
                RelayHeader(status: .recording, detail: "recording · \(timerLabel(vm.elapsedSeconds))")
                Spacer()
            }

            VStack(spacing: 28) {
                Circle()
                    .fill(Color.relayAmber)
                    .frame(width: 14, height: 14)
                    .shadow(color: .relayAmber.opacity(pulse ? 0.35 : 0.12), radius: pulse ? 12 : 6)
                    .scaleEffect(pulse ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)

                // Model status hint — only shown when there's a problem
                modelStatusView

                Text("listening…")
                    .font(.newsreader(size: 22, italic: true))
                    .foregroundStyle(Color.relayFaint)
                    .tracking(-0.2)

                // Language badge — shown once the model is ready
                if let lang = vm.speech.resolvedLanguageName {
                    Text(lang.lowercased())
                        .font(.jetbrainsMono(size: 10))
                        .foregroundStyle(Color.relayFaint)
                        .tracking(1.2)
                        .textCase(.uppercase)
                }

                WaveformView(level: max(0.15, vm.recorder.audioLevel), tint: .relayAmber, active: true)
            }

            VStack(spacing: 10) {
                Button {
                    vm.stopCapture()
                } label: {
                    HStack {
                        Spacer()
                        Text("tap to send")
                            .font(.relaySans(size: 16, weight: .medium))
                            .foregroundStyle(Color.relayInk)
                        Spacer()
                    }
                    .frame(height: RelaySpacing.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: RelaySpacing.buttonRadius)
                            .stroke(Color.relayHair2, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                if settings.tapMode {
                    Button {
                        vm.cancelCapture()
                    } label: {
                        Text("cancel")
                            .font(.jetbrainsMono(size: 10))
                            .foregroundStyle(Color.relayFaint)
                            .tracking(0.3)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("← slide to cancel")
                        .font(.jetbrainsMono(size: 10))
                        .foregroundStyle(Color.relayFaint)
                        .tracking(0.3)
                }
            }
            .padding(.horizontal, RelaySpacing.screenH)
            .padding(.bottom, RelaySpacing.ctaBottom)
        }
        .onAppear { pulse = true }
        .onChange(of: vm.recorder.audioLevel) { _, level in
            if level > 0.05 { vm.promoteToRecordingIfListening() }
        }
    }

    @ViewBuilder
    private var modelStatusView: some View {
        switch vm.speech.modelStatus {
        case .checking:
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.7)
                Text("loading speech model…")
                    .font(.jetbrainsMono(size: 10))
                    .foregroundStyle(Color.relayFaint)
            }

        case .unavailable(let reason):
            VStack(spacing: 4) {
                Label("speech model unavailable", systemImage: "waveform.slash")
                    .font(.jetbrainsMono(size: 10))
                    .foregroundStyle(Color.relayAmber)
                Text(reason)
                    .font(.jetbrainsMono(size: 9))
                    .foregroundStyle(Color.relayFaint)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.horizontal, 24)

        default:
            EmptyView()
        }
    }

    private func timerLabel(_ seconds: Int) -> String {
        String(format: "0:%02d", seconds)
    }
}
