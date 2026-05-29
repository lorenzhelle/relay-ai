import SwiftUI

struct WaveformView: View {
    var level: Float = 1.0    // 0–1 amplitude multiplier
    var tint: Color = .relayAmber
    var active: Bool = true

    private let barCount = 32
    private let heights: [CGFloat] = {
        (0..<32).map { i in
            let seed = sin(Double(i) * 1.31) * 0.5 + cos(Double(i) * 0.7) * 0.5
            return max(4, CGFloat(abs(seed)) * 30 + 4)
        }
    }()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(tint)
                    .frame(width: 3, height: heights[i] * CGFloat(level))
                    .opacity(active ? (0.55 + sin(Double(i) * 0.5) * 0.35) : 0.25)
                    .animation(.easeInOut(duration: 0.15), value: level)
            }
        }
        .frame(height: 44)
    }
}
