import SwiftUI

struct SettingsSheet: View {
    @Environment(AppCoordinator.self) private var appCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirmation = false
    @State private var copied = false

    private var channelId: String {
        (try? KeychainStore.shared.loadChannelId()) ?? "—"
    }

    var body: some View {
        ZStack {
            Color.relayBg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("settings")
                        .font(.relaySans(size: 19, weight: .medium))
                        .foregroundStyle(Color.relayInk)
                        .tracking(-0.2)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color.relayMuted)
                    }
                }
                .padding(.top, RelaySpacing.headerTop)
                .padding(.horizontal, RelaySpacing.screenH)
                .padding(.bottom, RelaySpacing.headerBottom)

                Divider().background(Color.relayHair)

                // Channel ID section
                VStack(alignment: .leading, spacing: 8) {
                    Text("channel id")
                        .font(.jetbrainsMono(size: 10))
                        .foregroundStyle(Color.relayFaint)
                        .tracking(1.2)
                        .textCase(.uppercase)

                    HStack(alignment: .top, spacing: 12) {
                        Text(channelId)
                            .font(.jetbrainsMono(size: 13))
                            .foregroundStyle(Color.relayInk)
                            .tracking(0.2)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)

                        Spacer()

                        Button {
                            UIPasteboard.general.string = channelId
                            withAnimation { copied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { copied = false }
                            }
                        } label: {
                            Text(copied ? "copied" : "copy")
                                .font(.jetbrainsMono(size: 10))
                                .foregroundStyle(copied ? Color.relaySage : Color.relayMuted)
                                .tracking(0.4)
                                .animation(.easeInOut(duration: 0.15), value: copied)
                        }
                    }
                    .padding(RelaySpacing.cardPad)
                    .overlay {
                        RoundedRectangle(cornerRadius: RelaySpacing.cardRadius)
                            .strokeBorder(style: StrokeStyle(lineWidth: 0.5, dash: [4, 3]))
                            .foregroundStyle(Color.relayHair2)
                    }

                    Text("trage diese ID in relay-agent/.env als CHANNEL_ID ein")
                        .font(.jetbrainsMono(size: 10))
                        .foregroundStyle(Color.relayFaint)
                        .tracking(0.2)
                        .lineSpacing(3)
                }
                .padding(.horizontal, RelaySpacing.screenH)
                .padding(.top, 24)

                Spacer()

                // Reset
                Divider().background(Color.relayHair)

                Button {
                    showResetConfirmation = true
                } label: {
                    Text("relay zurücksetzen")
                        .font(.jetbrainsMono(size: 11))
                        .foregroundStyle(Color.relayRust)
                        .tracking(0.3)
                        .padding(.horizontal, RelaySpacing.screenH)
                        .padding(.vertical, 20)
                }
                .confirmationDialog(
                    "Relay zurücksetzen?",
                    isPresented: $showResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Zurücksetzen", role: .destructive) {
                        dismiss()
                        appCoordinator.resetToOnboarding()
                    }
                    Button("Abbrechen", role: .cancel) {}
                } message: {
                    Text("Die Channel-ID wird gelöscht und das Onboarding startet neu.")
                }
            }
        }
    }
}

#Preview {
    SettingsSheet()
        .environment(AppCoordinator())
}
