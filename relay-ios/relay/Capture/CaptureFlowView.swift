import SwiftUI

struct CaptureFlowView: View {
    @Environment(CaptureViewModel.self) private var vm

    private var isActive: Bool {
        if case .idle = vm.state { return false }
        return true
    }

    var body: some View {
        if isActive {
            ZStack {
                switch vm.state {
                case .idle:
                    EmptyView()

                case .listening:
                    ListeningView()
                        .transition(.opacity)

                case .recording:
                    RecordingView()
                        .transition(.opacity)

                case .transcribing:
                    TranscribingView()
                        .transition(.opacity)

                case .captured(let capture):
                    AckView(capture: capture)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: stateKey)
        }
    }

    private var stateKey: String {
        switch vm.state {
        case .idle:          return "idle"
        case .listening:     return "listening"
        case .recording:     return "recording"
        case .transcribing:  return "transcribing"
        case .captured:      return "captured"
        }
    }
}
