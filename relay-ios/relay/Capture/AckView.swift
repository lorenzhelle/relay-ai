import SwiftUI

struct AckView: View {
    let capture: Capture
    @Environment(CaptureViewModel.self) private var vm
    @State private var autoTimer: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.relayBg.ignoresSafeArea()

            VStack(spacing: 0) {
                RelayHeader(status: .connected, detail: "local · queued")
                Spacer()
            }

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .stroke(Color.relaySage, lineWidth: 1.25)
                        .frame(width: 64, height: 64)
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(Color.relaySage)
                }

                Text("captured.")
                    .font(.newsreader(size: 26, italic: true))
                    .foregroundStyle(Color.relayInk)
                    .tracking(-0.4)

                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text(capture.shortId)
                            .font(.jetbrainsMono(size: 11))
                            .foregroundStyle(Color.relayMuted)
                        Text("·")
                            .font(.jetbrainsMono(size: 11))
                            .foregroundStyle(Color.relayFaint)
                        Text("queued · local")
                            .font(.jetbrainsMono(size: 11))
                            .foregroundStyle(Color.relayMuted)
                    }
                    .tracking(0.4)

                    Text(String(format: "%.2f s · offline", capture.durationSeconds))
                        .font(.jetbrainsMono(size: 10))
                        .foregroundStyle(Color.relayFaint)
                        .tracking(0.4)
                }
            }
            .onTapGesture {
                autoTimer?.cancel()
            }

            Text("this screen will fade in 2s · tap to keep")
                .font(.jetbrainsMono(size: 10))
                .foregroundStyle(Color.relayFaint)
                .tracking(0.4)
                .padding(.bottom, 60)
        }
        .onAppear {
            autoTimer = Task {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                vm.confirmCapture()
            }
        }
        .onDisappear {
            autoTimer?.cancel()
        }
    }
}
