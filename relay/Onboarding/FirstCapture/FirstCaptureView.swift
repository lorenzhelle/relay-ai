import SwiftUI

struct FirstCaptureView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @Environment(AppCoordinator.self) private var appCoordinator

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.relayBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Ein ruhiger Kanal \(Text("zu dem, was zu Hause auf dich wartet.").italic().foregroundStyle(Color.relayFaint))")
                            .font(.newsreader(size: 34))
                            .foregroundStyle(Color.relayInk)
                            .lineSpacing(4)
                            .tracking(-0.6)

                        VStack(spacing: 18) {
                            tipRow(number: "1", text: "Halt das Telefon ans Ohr oder drück den AirPods-Stem.")
                            tipRow(number: "2", text: "Sprich frei. Pausen sind okay. Multi-Item ist okay.")
                            tipRow(number: "3", text: "Loslassen. Claude legt es da ab, wo es hingehört.")
                        }
                        .padding(.top, 36)

                        connectionCard
                            .padding(.top, 40)
                    }
                    .padding(.horizontal, RelaySpacing.screenHWide)
                    .padding(.top, 20)
                    .padding(.bottom, 160)
                }
            }
            .scrollIndicators(.hidden)

            // Hold to speak button
            VStack(spacing: 10) {
                Button(action: { appCoordinator.onboardingComplete() }) {
                    HStack(spacing: 12) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 14))
                        Text("try it")
                            .font(.relaySans(size: 16, weight: .medium))
                            .tracking(-0.1)
                    }
                    .foregroundStyle(Color.relayOnInk)
                    .frame(maxWidth: .infinity)
                    .frame(height: RelaySpacing.buttonHeight)
                    .background(Color.relayInk)
                    .clipShape(RoundedRectangle(cornerRadius: RelaySpacing.buttonRadius))
                }
                .buttonStyle(.plain)

                Text("say anything · captured silently")
                    .font(.jetbrainsMono(size: 10))
                    .foregroundStyle(Color.relayFaint)
                    .tracking(0.3)
            }
            .padding(.horizontal, RelaySpacing.screenH)
            .padding(.bottom, RelaySpacing.ctaBottom)
        }
        .relayNavBar(status: .connected, detail: "paired · ready")
    }

    private func tipRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .strokeBorder(Color.relayHair2, lineWidth: 0.75)
                Text(number)
                    .font(.jetbrainsMono(size: 11))
                    .foregroundStyle(Color.relayMuted)
            }
            .frame(width: 22, height: 22)

            Text(text)
                .font(.newsreader(size: 17))
                .foregroundStyle(Color.relayInk)
                .lineSpacing(6)
                .tracking(-0.1)
                .padding(.top, 1)
        }
    }

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("verbunden via")
                .font(.jetbrainsMono(size: 10))
                .foregroundStyle(Color.relayFaint)
                .tracking(0.4)
            Text("@mein_relay_bot → claude code")
                .font(.jetbrainsMono(size: 13))
                .foregroundStyle(Color.relayInk)
                .tracking(0.2)
            Text("4 mcps available · obsidian, ticktick, home-assistant, gmail")
                .font(.jetbrainsMono(size: 10))
                .foregroundStyle(Color.relayFaint)
                .tracking(0.3)
                .padding(.top, 2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 0.5, dash: [4, 3]))
                .foregroundStyle(Color.relayHair2)
        }
    }
}

#Preview {
    FirstCaptureView()
        .environment(OnboardingCoordinator())
        .environment(AppCoordinator())
}
