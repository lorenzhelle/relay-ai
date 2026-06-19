import SwiftUI

struct WelcomeView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @State private var status: ConnectionStatus = .idle

    enum ConnectionStatus: Equatable {
        case idle, connecting, connected, failed(String)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.relayBg.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("Supabase Connection Test")
                    .font(.newsreader(size: 28))
                    .foregroundStyle(Color.relayInk)
                    .tracking(-0.5)

                statusView

                Button(action: testConnection) {
                    Text(status == .connecting ? "Connecting…" : "Test Connection")
                        .font(.relaySans(size: 15, weight: .medium))
                        .foregroundStyle(Color.relayOnInk)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.relayInk)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(status    == .connecting)

                Spacer()
            }
            .padding(.horizontal, RelaySpacing.screenHWide)

            if case .connected = status {
                OnboardBottom(
                    step: 1, total: 2,
                    primaryLabel: "Weiter",
                    secondaryLabel: nil,
                    action: { coordinator.advance(to: .channelId(UUID().uuidString.lowercased())) }
                )
            }
        }
        .relayNavBar(status: .offline, detail: "test")
    }

    @ViewBuilder
    private var statusView: some View {
        switch status {
        case .idle:
            Text("Noch kein Test durchgeführt")
                .font(.jetbrainsMono(size: 12))
                .foregroundStyle(Color.relayFaint)
        case .connecting:
            HStack(spacing: 8) {
                ProgressView()
                    .tint(Color.relayMuted)
                Text("Verbinde mit Supabase…")
                    .font(.jetbrainsMono(size: 12))
                    .foregroundStyle(Color.relayMuted)
            }
        case .connected:
            Label("Verbindung erfolgreich", systemImage: "checkmark.circle.fill")
                .font(.jetbrainsMono(size: 12))
                .foregroundStyle(Color.relayAmber)
        case .failed(let msg):
            VStack(spacing: 6) {
                Label("Verbindung fehlgeschlagen", systemImage: "xmark.circle.fill")
                    .font(.jetbrainsMono(size: 12))
                    .foregroundStyle(.red)
                Text(msg)
                    .font(.jetbrainsMono(size: 10))
                    .foregroundStyle(Color.relayFaint)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func testConnection() {
        status = .connecting
        Task {
            do {
                try await checkSupabaseConnection()
                await MainActor.run { status = .connected }
            } catch {
                await MainActor.run { status = .failed(error.localizedDescription) }
            }
        }
    }

    private func checkSupabaseConnection() async throws {
        let baseURL = SupabaseConfig.url
        print("Testing Supabase connection to \(baseURL.host ?? "unknown host")…")
        guard baseURL.host != "your-project.supabase.co" else {
            throw URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "Config.xcconfig: SUP_URL not set"])
        }
        guard !SupabaseConfig.anonKey.isEmpty else {
            throw URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "Config.xcconfig: SUP_ANON_KEY not set"])
        }

        let url = baseURL.appending(path: "/rest/v1/")
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "\(baseURL.host ?? "") → HTTP \(code)"])
        }
    }
}

#Preview {
    WelcomeView()
        .environment(OnboardingCoordinator())
}
