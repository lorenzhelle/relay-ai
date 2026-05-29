import SwiftUI

struct ListeningView: View {
    @Environment(CaptureViewModel.self) private var vm
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

                Text("listening…")
                    .font(.newsreader(size: 22, italic: true))
                    .foregroundStyle(Color.relayFaint)
                    .tracking(-0.2)

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

                Text("or pause 1.5s")
                    .font(.jetbrainsMono(size: 10))
                    .foregroundStyle(Color.relayFaint)
            }
            .padding(.horizontal, RelaySpacing.screenH)
            .padding(.bottom, RelaySpacing.ctaBottom)
        }
        .onAppear { pulse = true }
        .onChange(of: vm.recorder.audioLevel) { _, level in
            if level > 0.05 { vm.promoteToRecordingIfListening() }
        }
    }

    private func timerLabel(_ seconds: Int) -> String {
        String(format: "0:%02d", seconds)
    }
}
