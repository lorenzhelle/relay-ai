import SwiftUI

struct RecordingView: View {
    let transcript: String
    @Environment(CaptureViewModel.self) private var vm
    @State private var caretVisible: Bool = true

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.relayBg.ignoresSafeArea()

            VStack(spacing: 0) {
                RelayHeader(status: .recording, detail: "recording · \(timerLabel(vm.elapsedSeconds))")

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("transcript · on-device")
                            .font(.jetbrainsMono(size: 10))
                            .foregroundStyle(Color.relayFaint)
                            .tracking(1.2)
                            .textCase(.uppercase)

                        HStack(alignment: .bottom, spacing: 0) {
                            Text(transcript.isEmpty ? "…" : transcript)
                                .font(.newsreader(size: 22))
                                .foregroundStyle(Color.relayInk)
                                .tracking(-0.2)
                                .lineSpacing(6)

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

    private func timerLabel(_ seconds: Int) -> String {
        String(format: "0:%02d", seconds)
    }
}
