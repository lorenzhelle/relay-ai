import SwiftUI

struct WelcomeView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.relayBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Display headline
                        Text("Ein ruhiger Kanal \(Text("zu dem, was zu Hause auf dich wartet.").italic().foregroundStyle(Color.relayFaint))")
                            .font(.newsreader(size: 40))
                            .foregroundStyle(Color.relayInk)
                            .lineSpacing(4)
                            .tracking(-0.7)
                            .fixedSize(horizontal: false, vertical: true)

                        // Body
                        Text("Relay ist ein Mikrofon. Was du sagst, geht direkt an deine Claude-Code-Instanz — ohne Telegram, ohne Umwege, über einen lokalen Channel-Plugin.")
                            .font(.newsreader(size: 17))
                            .foregroundStyle(Color.relayMuted)
                            .lineSpacing(8)
                            .tracking(-0.1)
                            .padding(.top, 24)

                        // Prerequisites card
                        prerequisitesCard
                            .padding(.top, 32)
                    }
                    .padding(.horizontal, RelaySpacing.screenHWide)
                    .padding(.top, 20)
                    .padding(.bottom, 180)
                }
            }
            .scrollIndicators(.hidden)

            OnboardBottom(
                step: 1, total: 4,
                primaryLabel: "Rechner ist bereit",
                secondaryLabel: "sonst erst dort einrichten",
                action: { coordinator.advance(to: .pairingCode) }
            )
        }
        .relayNavBar(status: .offline, detail: "not paired")
    }

    private var prerequisitesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("auf deinem Rechner · einmalig")
                    .font(.jetbrainsMono(size: 10))
                    .foregroundStyle(Color.relayFaint)
                    .tracking(1.2)
                    .textCase(.uppercase)
                Spacer()
                Text("~5 min")
                    .font(.jetbrainsMono(size: 10))
                    .foregroundStyle(Color.relayFaint)
            }
            .padding(.bottom, 14)

            VStack(alignment: .leading, spacing: 14) {
                prerequisiteRow(
                    number: "1",
                    text: "Claude Code installiert",
                    hint: "claude muss im PATH erreichbar sein"
                )
                prerequisiteRow(
                    number: "2",
                    text: "Bun installiert",
                    hint: "bun.sh · wird vom Relay-Plugin gebraucht"
                )
                prerequisiteRow(
                    number: "3",
                    command: "claude --dangerously-load-development-channels server:relay",
                    hint: "auf der Maschine mit deiner Claude-Session ausführen"
                )
                prerequisiteRow(
                    number: "4",
                    text: "Pairing-Code notieren",
                    hint: "Claude zeigt ihn beim Start an — 6 Zeichen"
                )
            }

            Divider()
                .background(Color.relayHair)
                .padding(.top, 14)

            Text("Anleitung steht in der README · kein Telegram, kein eigener Bot")
                .font(.jetbrainsMono(size: 10))
                .foregroundStyle(Color.relayFaint)
                .tracking(0.3)
                .lineSpacing(4)
                .padding(.top, 10)
        }
        .padding(RelaySpacing.cardPad)
        .overlay {
            RoundedRectangle(cornerRadius: RelaySpacing.cardRadius)
                .strokeBorder(style: StrokeStyle(lineWidth: 0.5, dash: [4, 3]))
                .foregroundStyle(Color.relayHair2)
        }
    }

    private func prerequisiteRow(number: String, text: String? = nil, command: String? = nil, hint: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.jetbrainsMono(size: 10.5))
                .foregroundStyle(Color.relayFaint)
                .frame(width: 12, alignment: .leading)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                if let command {
                    Text(command)
                        .font(.jetbrainsMono(size: 11.5))
                        .foregroundStyle(Color.relayInk)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                } else if let text {
                    Text(text)
                        .font(.newsreader(size: 14))
                        .foregroundStyle(Color.relayInk)
                        .lineSpacing(4)
                        .tracking(-0.05)
                }

                Text(hint)
                    .font(.jetbrainsMono(size: 10))
                    .foregroundStyle(Color.relayFaint)
                    .lineSpacing(3)
                    .tracking(0.2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environment(OnboardingCoordinator())
}
