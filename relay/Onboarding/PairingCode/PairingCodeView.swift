import SwiftUI

struct PairingCodeView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @State private var vm: PairingCodeViewModel
    @State private var pulseScale: CGFloat = 1
    @State private var pulseOpacity: Double = 1

    init(botToken: String, chatId: String, initialCode: String) {
        _vm = State(initialValue: PairingCodeViewModel(botToken: botToken, chatId: chatId, initialCode: initialCode))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.relayBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Sag deiner Claude, dass das du bist.")
                            .font(.newsreader(size: 28))
                            .foregroundStyle(Color.relayInk)
                            .tracking(-0.4)

                        Text("Relay hat eine Nachricht an deinen Bot geschickt. Dein Rechner hat geantwortet — mit diesem Code:")
                            .font(.newsreader(size: 14.5, italic: true))
                            .foregroundStyle(Color.relayMuted)
                            .lineSpacing(6)
                            .tracking(-0.05)
                            .padding(.top, 8)

                        codeCard
                            .padding(.top, 22)

                        commandCard
                            .padding(.top, 22)

                        waitingIndicator
                            .padding(.top, 22)
                    }
                    .padding(.horizontal, RelaySpacing.screenH)
                    .padding(.top, 14)
                    .padding(.bottom, 200)
                }
            }
            .scrollIndicators(.hidden)

            OnboardBottom(
                step: 3, total: 5,
                primaryLabel: "neuen Code anfragen",
                primaryStyle: .ghost,
                secondaryLabel: "Rechner nicht erreichbar? Bot-Username prüfen",
                action: {
                    vm.requestNewCode { _ in }
                }
            )
            .disabled(vm.isPolling)
            .opacity(vm.isExpired ? 1 : 0.4)
        }
        .onAppear {
            startPulse()
            vm.startPolling { result in
                coordinator.advance(to: .paired(result))
            }
        }
        .onDisappear { vm.cancelTasks() }
        .relayNavBar(status: .offline, detail: "warte auf claude code")
    }

    private var codeCard: some View {
        VStack(spacing: 12) {
            Text("PAIRING CODE · 90 S GÜLTIG")
                .font(.jetbrainsMono(size: 10))
                .foregroundStyle(Color.relayFaint)
                .tracking(1.2)

            Text(vm.displayCode)
                .font(.jetbrainsMono(size: 22, weight: .medium))
                .foregroundStyle(Color.relayInk)
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 18)
        .background(Color.relayPaper)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.relayHair2, lineWidth: 0.5)
        }
    }

    private var commandCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TIPP DAS IN CLAUDE CODE")
                    .font(.jetbrainsMono(size: 10))
                    .foregroundStyle(Color.relayFaint)
                    .tracking(1.2)
                Spacer()
                Button(action: vm.copyCommand) {
                    Text("copy")
                        .font(.jetbrainsMono(size: 10))
                        .foregroundStyle(Color.relayInk)
                        .tracking(0.3)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text("> ")
                        .foregroundStyle(Color.relayOnInk.opacity(0.45))
                    Text("/telegram:access pair")
                        .foregroundStyle(Color.relayOnInk)
                }
                Text(vm.pairingCode.lowercased())
                    .foregroundStyle(Color.relayOnInk)
                    .padding(.leading, 14)
            }
            .font(.jetbrainsMono(size: 12.5))
            .lineSpacing(4)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.relayInk)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var waitingIndicator: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.relayAmber.opacity(0.22))
                    .frame(width: 18, height: 18)
                    .scaleEffect(pulseScale)
                    .opacity(pulseOpacity)
                Circle()
                    .fill(Color.relayAmber)
                    .frame(width: 8, height: 8)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Warte auf Bestätigung vom Rechner…")
                    .font(.newsreader(size: 14))
                    .foregroundStyle(Color.relayInk)
                    .tracking(-0.05)
                Text("schliesst von selbst, sobald der Code erkannt ist")
                    .font(.jetbrainsMono(size: 10))
                    .foregroundStyle(Color.relayFaint)
                    .tracking(0.3)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 0.5, dash: [4, 3]))
                .foregroundStyle(Color.relayHair2)
        }
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
            pulseOpacity = 0.6
        }
    }
}

#Preview {
    PairingCodeView(botToken: "123:preview", chatId: "84219", initialCode: "OAK-RIVER-7142")
        .environment(OnboardingCoordinator())
}
