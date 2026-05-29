import SwiftUI

struct PairingCodeView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @State private var vm = PairingCodeViewModel()
    @FocusState private var codeFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.relayBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Enter the pairing code.")
                            .font(.newsreader(size: 28))
                            .foregroundStyle(Color.relayInk)
                            .tracking(-0.4)

                        Text("Claude showed you this when the relay plugin started.")
                            .font(.newsreader(size: 14.5, italic: true))
                            .foregroundStyle(Color.relayMuted)
                            .lineSpacing(6)
                            .tracking(-0.05)
                            .padding(.top, 8)

                        codeInputField
                            .padding(.top, 26)

                        hintCard
                            .padding(.top, 20)

                        if let error = vm.errorMessage {
                            Text(error)
                                .font(.jetbrainsMono(size: 10))
                                .foregroundStyle(Color.relayRust)
                                .tracking(0.2)
                                .padding(.top, 12)
                        }
                    }
                    .padding(.horizontal, RelaySpacing.screenH)
                    .padding(.top, 14)
                    .padding(.bottom, 200)
                }
            }
            .scrollIndicators(.hidden)
            .onTapGesture { codeFocused = false }

            OnboardBottom(
                step: 2, total: 4,
                primaryLabel: vm.isConfirming ? "…" : "Pair",
                action: {
                    vm.confirm { result in
                        coordinator.advance(to: .paired(result))
                    }
                }
            )
            .disabled(!vm.canConfirm || vm.isConfirming)
        }
        .onAppear { codeFocused = true }
        .relayNavBar(status: .offline, detail: "pairing")
    }

    private var codeInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PAIRING CODE")
                .font(.jetbrainsMono(size: 10))
                .foregroundStyle(Color.relayFaint)
                .tracking(1.2)

            ZStack(alignment: .leading) {
                if vm.codeInput.isEmpty {
                    Text("ABC123")
                        .font(.jetbrainsMono(size: 16))
                        .foregroundStyle(Color.relayFaint.opacity(0.5))
                }
                TextField("", text: $vm.codeInput)
                    .font(.jetbrainsMono(size: 16))
                    .foregroundStyle(Color.relayInk)
                    .focused($codeFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .onChange(of: vm.codeInput) { _, new in
                        if new.count > 6 {
                            vm.codeInput = String(new.prefix(6))
                        }
                    }
            }
            .padding(14)
            .background(Color.relayPaper)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(codeFocused ? Color.relayInk : Color.relayHair2,
                                  lineWidth: codeFocused ? 1 : 0.5)
            }

            Text("6 characters · shown in your Claude Code session")
                .font(.jetbrainsMono(size: 10))
                .foregroundStyle(Color.relayFaint)
                .tracking(0.3)
        }
    }

    private var hintCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HAVEN'T RUN THE PLUGIN YET?")
                .font(.jetbrainsMono(size: 10))
                .foregroundStyle(Color.relayFaint)
                .tracking(1.2)

            HStack(spacing: 0) {
                Text("$ ")
                    .foregroundStyle(Color.relayFaint)
                Text("claude --dangerously-load-development-channels server:relay")
                    .foregroundStyle(Color.relayInk)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .font(.jetbrainsMono(size: 11))
        }
        .padding(14)
        .background(Color.relayPaper)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.relayHair2, lineWidth: 0.5)
        }
    }
}

#Preview {
    PairingCodeView()
        .environment(OnboardingCoordinator())
}
