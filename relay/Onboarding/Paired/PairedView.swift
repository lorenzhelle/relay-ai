import SwiftUI

struct PairedView: View {
    let result: PairingResult

    @Environment(OnboardingCoordinator.self) private var coordinator
    @State private var vm: PairedViewModel
    @State private var ringProgress: CGFloat = 0
    @State private var contentVisible: Bool = false
    @State private var contentOffset: CGFloat = 12

    init(result: PairingResult) {
        self.result = result
        _vm = State(initialValue: PairedViewModel(result: result))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.relayBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Success ring + checkmark
                        successRing
                            .padding(.top, 48)

                        // Headline
                        Text("Verbunden.")
                            .font(.newsreader(size: 36))
                            .foregroundStyle(Color.relayInk)
                            .tracking(-0.6)
                            .padding(.top, 22)

                        Text("Dein Bot ist gepaart, Claude Code hört zu. Erster Round-trip war \(result.roundTripMs.map { "\($0) ms" } ?? "—") — Telegram ist halt nicht der schnellste, aber stabil.")
                            .font(.newsreader(size: 17, italic: true))
                            .foregroundStyle(Color.relayMuted)
                            .lineSpacing(6)
                            .tracking(-0.1)
                            .padding(.top, 10)

                        // Metadata rows
                        metadataSection
                            .padding(.top, 32)

                        // Whisper progress
                        whisperSection
                            .padding(.top, 26)
                    }
                    .padding(.horizontal, RelaySpacing.screenHWide)
                    .padding(.bottom, 160)
                    .opacity(contentVisible ? 1 : 0)
                    .offset(y: contentVisible ? 0 : contentOffset)
                }
            }
            .scrollIndicators(.hidden)

            OnboardBottom(
                step: 4, total: 5,
                primaryLabel: "weiter",
                action: { coordinator.advance(to: .triggerPick) }
            )
        }
        .onAppear {
            // Draw ring → then reveal content
            withAnimation(.easeOut(duration: 0.5)) {
                ringProgress = 1
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.5)) {
                contentVisible = true
                contentOffset = 0
            }
            vm.startWhisperDownload()
        }
        .onDisappear { vm.cancel() }
        .relayNavBar(status: .connected, detail: "verbunden")
    }

    private var successRing: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(Color.relaySage, lineWidth: 1.25)
                .frame(width: 56, height: 56)
                .rotationEffect(.degrees(-90))

            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Color.relaySage)
                .opacity(ringProgress > 0.9 ? 1 : 0)
        }
    }

    private var metadataSection: some View {
        VStack(spacing: 12) {
            Divider().background(Color.relayHair)

            let rows: [(String, String)] = [
                ("bot",         result.botUsername),
                ("chat-id",     maskChatId(result.chatId)),
                ("channel",     result.channel),
                ("claude code", "up"),
                ("mcps",        result.mcps.isEmpty ? "—" : "\(result.mcps.count) · \(result.mcps.joined(separator: " · "))"),
            ]
            ForEach(rows, id: \.0) { key, value in
                HStack {
                    Text(key)
                        .font(.jetbrainsMono(size: 11.5))
                        .foregroundStyle(Color.relayFaint)
                    Spacer()
                    Text(value)
                        .font(.jetbrainsMono(size: 11.5))
                        .foregroundStyle(Color.relayInk)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 200, alignment: .trailing)
                }
                .tracking(0.2)
            }
        }
    }

    private var whisperSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("whisper base · multilingual")
                    .font(.jetbrainsMono(size: 11))
                    .foregroundStyle(Color.relayMuted)
                Spacer()
                Text("\(vm.whisperReceived) / \(vm.whisperTotal) MB")
                    .font(.jetbrainsMono(size: 11))
                    .foregroundStyle(Color.relayMuted)
            }
            .tracking(0.2)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.relayHair)
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.relaySage)
                        .frame(width: geo.size.width * vm.whisperProgress, height: 3)
                }
            }
            .frame(height: 3)
        }
    }

    private func maskChatId(_ id: String) -> String {
        guard id.count > 4 else { return id }
        let visible = id.prefix(5)
        return visible + String(repeating: "·", count: 4)
    }
}

#Preview {
    PairedView(result: PairingResult(
        botUsername: "@mein_relay_bot",
        botToken: "123:preview",
        chatId: "84219",
        channel: "telegram@claude-plugins-official",
        roundTripMs: 412,
        mcps: ["obsidian", "ticktick", "home", "gmail"]
    ))
    .environment(OnboardingCoordinator())
}
