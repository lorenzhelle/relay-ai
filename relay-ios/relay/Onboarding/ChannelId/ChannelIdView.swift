import SwiftUI

struct ChannelIdView: View {
    let channelId: String

    @Environment(OnboardingCoordinator.self) private var coordinator
    @Environment(AppCoordinator.self) private var appCoordinator
    @State private var copied = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.relayBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Deine Channel-ID")
                        .font(.newsreader(size: 34))
                        .foregroundStyle(Color.relayInk)
                        .tracking(-0.6)

                    Text("Trag sie einmalig in relay-agent/.env ein. Danach verbindet sich der Agent automatisch.")
                        .font(.newsreader(size: 17, italic: true))
                        .foregroundStyle(Color.relayMuted)
                        .lineSpacing(6)
                        .padding(.top, 12)

                    // ID card
                    VStack(alignment: .leading, spacing: 12) {
                        Text(channelId)
                            .font(.jetbrainsMono(size: 14))
                            .foregroundStyle(Color.relayInk)
                            .tracking(0.2)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)

                        Button {
                            UIPasteboard.general.string = channelId
                            withAnimation { copied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { copied = false }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 12, weight: .regular))
                                Text(copied ? "kopiert" : "kopieren")
                                    .font(.jetbrainsMono(size: 11))
                                    .tracking(0.3)
                            }
                            .foregroundStyle(copied ? Color.relaySage : Color.relayMuted)
                            .animation(.easeInOut(duration: 0.15), value: copied)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(RelaySpacing.cardPad)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay {
                        RoundedRectangle(cornerRadius: RelaySpacing.cardRadius)
                            .strokeBorder(style: StrokeStyle(lineWidth: 0.5, dash: [4, 3]))
                            .foregroundStyle(Color.relayHair2)
                    }
                    .padding(.top, 32)

                    // Instruction
                    VStack(alignment: .leading, spacing: 14) {
                        instructionRow(
                            number: "1",
                            command: "CHANNEL_ID=\(channelId)",
                            hint: "in relay-agent/.env eintragen"
                        )
                        instructionRow(
                            number: "2",
                            command: "claude --dangerously-load-development-channels server:relay",
                            hint: "relay-agent starten — ab jetzt verbunden"
                        )
                    }
                    .padding(.top, 28)
                }
                .padding(.horizontal, RelaySpacing.screenHWide)
                .padding(.top, 20)
                .padding(.bottom, 180)
            }
            .scrollIndicators(.hidden)

            OnboardBottom(
                step: 3, total: 3,
                primaryLabel: "relay-agent ist gestartet",
                secondaryLabel: "ID ist jederzeit in den Einstellungen",
                action: {
                    try? KeychainStore.shared.save(channelId: channelId)
                    appCoordinator.onboardingComplete()
                }
            )
        }
        .relayNavBar(status: .offline, detail: "not connected yet")
    }

    private func instructionRow(number: String, command: String, hint: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.jetbrainsMono(size: 10.5))
                .foregroundStyle(Color.relayFaint)
                .frame(width: 12, alignment: .leading)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(command)
                    .font(.jetbrainsMono(size: 11.5))
                    .foregroundStyle(Color.relayInk)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

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
    ChannelIdView(channelId: "a1b2c3d4-e5f6-7890-abcd-ef1234567890")
        .environment(OnboardingCoordinator())
        .environment(AppCoordinator())
}
