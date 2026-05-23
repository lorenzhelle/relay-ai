import SwiftUI

// Scaffold — the captures log and "hold to speak" live here in the next phase.
struct HomeView: View {
    var body: some View {
        ZStack {
            Color.relayBg.ignoresSafeArea()
            VStack(spacing: 12) {
                RelayHeader(status: .connected, detail: "@relay_bot · —")
                Spacer()
                Text("paired · ready")
                    .font(.jetbrainsMono(size: 13))
                    .foregroundStyle(Color.relayFaint)
                    .tracking(0.4)
                Spacer()
            }
        }
    }
}

#Preview {
    HomeView()
}
