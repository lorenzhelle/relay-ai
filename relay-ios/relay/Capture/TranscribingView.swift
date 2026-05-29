import SwiftUI

struct TranscribingView: View {
    @State private var dotCount = 0

    var body: some View {
        ZStack {
            Color.relayBg.ignoresSafeArea()
            VStack(spacing: 20) {
                RelayHeader(status: .recording, detail: "transcribing…")
                Spacer()
                Text("transcribing" + String(repeating: ".", count: dotCount))
                    .font(.newsreader(size: 20, italic: true))
                    .foregroundStyle(Color.relayFaint)
                    .tracking(-0.2)
                Spacer()
            }
        }
        .task {
            while true {
                try? await Task.sleep(for: .milliseconds(400))
                dotCount = (dotCount + 1) % 4
            }
        }
    }
}
