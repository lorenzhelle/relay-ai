import SwiftUI

enum OnboardButtonStyle {
    case solid, ghost
}

struct OnboardBottom: View {
    let step: Int
    let total: Int
    let primaryLabel: String
    var primaryStyle: OnboardButtonStyle = .solid
    var secondaryLabel: String? = nil
    let action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            stepDots

            Button(action: action) {
                Text(primaryLabel)
                    .font(.relaySans(size: 16, weight: .medium))
                    .tracking(-0.1)
                    .foregroundStyle(primaryStyle == .solid ? Color.relayOnInk : Color.relayInk)
                    .frame(maxWidth: .infinity)
                    .frame(height: RelaySpacing.buttonHeight)
                    .background {
                        RoundedRectangle(cornerRadius: RelaySpacing.buttonRadius)
                            .fill(primaryStyle == .solid ? Color.relayInk : Color.clear)
                            .overlay {
                                if primaryStyle == .ghost {
                                    RoundedRectangle(cornerRadius: RelaySpacing.buttonRadius)
                                        .strokeBorder(Color.relayHair2, lineWidth: 1)
                                }
                            }
                    }
            }
            .buttonStyle(.plain)

            if let secondary = secondaryLabel {
                Text(secondary)
                    .font(.jetbrainsMono(size: 11))
                    .foregroundStyle(Color.relayFaint)
                    .tracking(0.3)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, RelaySpacing.screenH)
        .padding(.bottom, RelaySpacing.ctaBottom)
    }

    private var stepDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(i < step ? Color.relayInk : Color.relayHair2)
                    .frame(width: i == step - 1 ? 18 : 6, height: 6)
                    .animation(.spring(duration: 0.3), value: step)
            }
        }
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Color.relayBg.ignoresSafeArea()
        OnboardBottom(
            step: 2, total: 5,
            primaryLabel: "Nachricht schicken",
            secondaryLabel: "Relay schickt /start an den Bot",
            action: {}
        )
    }
}
