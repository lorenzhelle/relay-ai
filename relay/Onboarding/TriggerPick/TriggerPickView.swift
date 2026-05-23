import SwiftUI

struct TriggerPickView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @State private var vm = TriggerPickViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.relayBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Wie öffnest du Relay?")
                            .font(.newsreader(size: 30))
                            .foregroundStyle(Color.relayInk)
                            .tracking(-0.5)

                        Text("Wähl einen Trigger. Die anderen kannst du später auch noch dazu legen.")
                            .font(.newsreader(size: 15, italic: true))
                            .foregroundStyle(Color.relayMuted)
                            .lineSpacing(6)
                            .padding(.top, 8)

                        // Phone silhouette diagram
                        phoneDiagram
                            .padding(.top, 22)
                            .padding(.bottom, 24)

                        // Trigger options
                        VStack(spacing: 10) {
                            ForEach([RelayTrigger.actionButton, .airpodsStem, .lockScreenShortcut], id: \.label) { trigger in
                                TriggerOptionRow(
                                    trigger: trigger,
                                    isSelected: vm.selected == trigger,
                                    onTap: { vm.select(trigger) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, RelaySpacing.screenHWide)
                    .padding(.top, 20)
                    .padding(.bottom, 180)
                }
            }
            .scrollIndicators(.hidden)

            OnboardBottom(
                step: 5, total: 5,
                primaryLabel: "Shortcut installieren",
                secondaryLabel: "oder später · Settings → Trigger",
                action: {
                    vm.installTrigger()
                    coordinator.advance(to: .firstCapture)
                }
            )
        }
        .relayNavBar(status: .connected, detail: "last step")
    }

    private var phoneDiagram: some View {
        HStack {
            Spacer()
            Canvas { ctx, _ in
                let amber = UIColor(Color.relayAmber)
                let hair2 = UIColor(Color.relayHair2)
                let paper = UIColor(Color.relayPaper)
                let bg    = UIColor(Color.relayBg)

                // Phone body
                let body = CGRect(x: 28, y: 6, width: 64, height: 88)
                let bodyPath = UIBezierPath(roundedRect: body, cornerRadius: 14)
                ctx.withCGContext { cg in
                    cg.setFillColor(paper.cgColor)
                    cg.setStrokeColor(hair2.cgColor)
                    cg.setLineWidth(1)
                    bodyPath.fill()
                    bodyPath.stroke()

                    // Screen
                    let screen = CGRect(x: 33, y: 11, width: 54, height: 78)
                    let screenPath = UIBezierPath(roundedRect: screen, cornerRadius: 9)
                    cg.setFillColor(bg.cgColor)
                    screenPath.fill()

                    // Action button (amber)
                    let btn = CGRect(x: 25, y: 30, width: 4, height: 14)
                    let btnPath = UIBezierPath(roundedRect: btn, cornerRadius: 1.5)
                    cg.setFillColor(amber.cgColor)
                    btnPath.fill()

                    // Volume buttons
                    for y in [28.0, 42.0] {
                        let vBtn = CGRect(x: 91, y: y, width: 4, height: y == 28 ? 9 : 14)
                        let vPath = UIBezierPath(roundedRect: vBtn, cornerRadius: 1.5)
                        cg.setFillColor(hair2.cgColor)
                        vPath.fill()
                    }

                    // Label line
                    cg.setStrokeColor(amber.cgColor)
                    cg.setLineWidth(0.75)
                    cg.move(to: CGPoint(x: 22, y: 37))
                    cg.addLine(to: CGPoint(x: 8, y: 37))
                    cg.strokePath()
                }
            }
            .frame(width: 120, height: 100)
            Spacer()
        }
    }
}

struct TriggerOptionRow: View {
    let trigger: RelayTrigger
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon box
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.relayInk : Color.clear)
                        .overlay {
                            if !isSelected {
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.relayHair2, lineWidth: 0.5)
                            }
                        }
                    Image(systemName: trigger.systemImage)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(isSelected ? Color.relayOnInk : Color.relayInk)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(trigger.label)
                        .font(.relaySans(size: 15, weight: .medium))
                        .foregroundStyle(Color.relayInk)
                        .tracking(-0.1)
                    Text(trigger.hint)
                        .font(.jetbrainsMono(size: 10.5))
                        .foregroundStyle(Color.relayFaint)
                        .tracking(0.2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.relayInk)
                }
            }
            .padding(14)
            .background(isSelected ? Color.relayPaper : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color.relayInk : Color.relayHair2,
                                  lineWidth: isSelected ? 1.5 : 0.5)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    TriggerPickView()
        .environment(OnboardingCoordinator())
}
