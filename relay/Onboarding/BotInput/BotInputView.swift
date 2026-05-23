import SwiftUI

struct BotInputView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @State private var vm = BotInputViewModel()
    @FocusState private var fieldFocused: Bool
    @State private var tokenMode = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.relayBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Dein Bot ist die Leitung.")
                            .font(.newsreader(size: 28))
                            .foregroundStyle(Color.relayInk)
                            .tracking(-0.4)

                        Text("Gib den Username deines Telegram-Bots ein — den, den du via BotFather erstellt und auf deinem Rechner konfiguriert hast.")
                            .font(.newsreader(size: 14.5, italic: true))
                            .foregroundStyle(Color.relayMuted)
                            .lineSpacing(6)
                            .tracking(-0.05)
                            .padding(.top, 8)

                        botInputField
                            .padding(.top, 26)

                        recapCard
                            .padding(.top, 26)

                        tokenModeLink
                            .padding(.top, 20)
                    }
                    .padding(.horizontal, RelaySpacing.screenH)
                    .padding(.top, 14)
                    .padding(.bottom, 200)
                }
            }
            .scrollIndicators(.hidden)
            .onTapGesture { fieldFocused = true }

            OnboardBottom(
                step: 2, total: 5,
                primaryLabel: vm.isLoading ? "Wird gesendet…" : "Nachricht schicken",
                secondaryLabel: "Relay schickt /start an den Bot und wartet auf den Pairing-Code",
                action: {
                    vm.submit { token, chatId, code in
                        coordinator.advance(to: .pairingCode(botToken: token, chatId: chatId, initialCode: code))
                    }
                }
            )
        }
        .onAppear { fieldFocused = true }
        .relayNavBar(status: .offline, detail: "bot · setup")
    }

    private var botInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tokenMode ? "BOT TOKEN" : "BOT USERNAME")
                .font(.jetbrainsMono(size: 10))
                .foregroundStyle(Color.relayFaint)
                .tracking(1.2)

            HStack(spacing: 2) {
                if !tokenMode {
                    Text("@")
                        .font(.jetbrainsMono(size: 16))
                        .foregroundStyle(Color.relayFaint)
                }

                ZStack(alignment: .leading) {
                    if vm.botInput.isEmpty {
                        Text(tokenMode ? "123456:ABCxyz-token" : "mein_relay_bot")
                            .font(.jetbrainsMono(size: 16))
                            .foregroundStyle(Color.relayFaint.opacity(0.5))
                    }
                    TextField("", text: $vm.botInput)
                        .font(.jetbrainsMono(size: 16))
                        .foregroundStyle(Color.relayInk)
                        .focused($fieldFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
            }
            .padding(14)
            .background(Color.relayPaper)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(fieldFocused ? Color.relayInk : Color.relayHair2, lineWidth: fieldFocused ? 1 : 0.5)
            }

            if let error = vm.errorMessage {
                Text(error)
                    .font(.jetbrainsMono(size: 10))
                    .foregroundStyle(Color.relayRust)
                    .tracking(0.2)
            } else {
                Text(tokenMode
                     ? "aus BotFather · nach /newbot und /mybots"
                     : "findest du in BotFather · Format @name oder t.me/name")
                    .font(.jetbrainsMono(size: 10))
                    .foregroundStyle(Color.relayFaint)
                    .tracking(0.3)
            }
        }
    }

    private var recapCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("AUF DEINEM RECHNER, VORHER")
                    .font(.jetbrainsMono(size: 10))
                    .foregroundStyle(Color.relayFaint)
                    .tracking(0.5)
                Spacer()
                Text("✓ erledigt?")
                    .font(.jetbrainsMono(size: 10))
                    .foregroundStyle(Color.relayFaint)
            }

            ForEach([
                "/plugin install telegram@claude-plugins-official",
                "/telegram:configure <token>",
                "claude --channels plugin:telegram@…",
            ], id: \.self) { line in
                HStack(spacing: 0) {
                    Text("$ ")
                        .font(.jetbrainsMono(size: 11.5))
                        .foregroundStyle(Color.relayFaint)
                    Text(line)
                        .font(.jetbrainsMono(size: 11.5))
                        .foregroundStyle(Color.relayInk)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        }
        .padding(14)
        .background(Color.relayPaper)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.relayHair2, lineWidth: 0.5)
        }
    }

    private var tokenModeLink: some View {
        HStack(alignment: .top) {
            Text("• token lieber direkt eintippen?")
                .font(.jetbrainsMono(size: 10.5))
                .foregroundStyle(Color.relayFaint)
                .tracking(0.2)
            Spacer()
            Button {
                tokenMode.toggle()
                vm.botInput = ""
            } label: {
                Text(tokenMode ? "Username\nstatt Token" : "Token statt\nUsername")
                    .font(.jetbrainsMono(size: 10.5))
                    .foregroundStyle(Color.relayInk)
                    .underline()
                    .multilineTextAlignment(.trailing)
                    .tracking(0.2)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    BotInputView()
        .environment(OnboardingCoordinator())
}
