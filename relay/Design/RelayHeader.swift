import SwiftUI

enum RelayStatus {
    case connected, recording, offline, speaking

    var dotColor: Color {
        switch self {
        case .connected: .relaySage
        case .recording: .relayAmber
        case .offline:   .relayRust
        case .speaking:  .relayAmber
        }
    }

    var hasHalo: Bool {
        self == .recording || self == .speaking
    }
}

// MARK: - Embedded header view (kept for Home screen use)

struct RelayHeader: View {
    let status: RelayStatus
    let detail: String

    var body: some View {
        HStack(alignment: .bottom) {
            HStack(spacing: 8) {
                ZStack {
                    if status.hasHalo {
                        Circle()
                            .fill(Color.relayAmber.opacity(0.22))
                            .frame(width: 16, height: 16)
                    }
                    Circle()
                        .fill(status.dotColor)
                        .frame(width: 8, height: 8)
                }
                Text("relay")
                    .font(.relaySans(size: 19, weight: .medium))
                    .foregroundStyle(Color.relayInk)
                    .tracking(-0.2)
            }

            Spacer()

            Text(detail)
                .font(.jetbrainsMono(size: 10.5))
                .foregroundStyle(Color.relayMuted)
                .tracking(0.2)
                .textCase(.lowercase)
        }
        .padding(.top, RelaySpacing.headerTop)
        .padding(.horizontal, RelaySpacing.screenH)
        .padding(.bottom, RelaySpacing.headerBottom)
    }
}

// MARK: - Nav bar toolbar modifier

struct RelayNavBar: ViewModifier {
    let status: RelayStatus
    let detail: String

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 7) {
                        ZStack {
                            if status.hasHalo {
                                Circle()
                                    .fill(status.dotColor.opacity(0.22))
                                    .frame(width: 14, height: 14)
                            }
                            Circle()
                                .fill(status.dotColor)
                                .frame(width: 7, height: 7)
                        }
                        Text("relay")
                            .font(.relaySans(size: 17, weight: .medium))
                            .foregroundStyle(Color.relayInk)
                            .tracking(-0.2)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Text(detail)
                        .font(.jetbrainsMono(size: 10))
                        .foregroundStyle(Color.relayMuted)
                        .tracking(0.2)
                        .textCase(.lowercase)
                        .multilineTextAlignment(.trailing)
                }
            }
    }
}

extension View {
    func relayNavBar(status: RelayStatus, detail: String) -> some View {
        modifier(RelayNavBar(status: status, detail: detail))
    }
}

#Preview {
    VStack(spacing: 0) {
        RelayHeader(status: .offline, detail: "not paired")
        RelayHeader(status: .connected, detail: "@relay_bot · 412 ms")
        RelayHeader(status: .recording, detail: "recording · 0:03")
    }
    .background(Color.relayBg)
}
