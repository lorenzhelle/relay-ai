import SwiftUI

struct HomeView: View {
    @Environment(CaptureViewModel.self) private var captureVM
    @Environment(CaptureStore.self) private var store

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.relayBg.ignoresSafeArea()

            VStack(spacing: 0) {
                RelayHeader(status: .connected, detail: "local · queued")

                if store.captures.isEmpty {
                    Spacer()
                    Text("no captures yet")
                        .font(.newsreader(size: 18, italic: true))
                        .foregroundStyle(Color.relayFaint)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                            ForEach(capturesByDay) { day in
                                DayLabel(day.label)
                                ForEach(day.captures) { capture in
                                    CaptureRowView(capture: capture)
                                }
                            }
                        }
                        .padding(.bottom, 140)
                    }
                    .scrollIndicators(.hidden)
                }
            }

            HoldToSpeakButton()
                .padding(.horizontal, RelaySpacing.screenH)
                .padding(.bottom, RelaySpacing.ctaBottom)
        }
        .overlay {
            CaptureFlowView()
        }
    }

    private var capturesByDay: [CaptureDay] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.captures) {
            calendar.startOfDay(for: $0.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }.map { date, captures in
            CaptureDay(
                id: date.formatted(.iso8601),
                label: dayLabel(for: date, calendar: calendar),
                captures: captures.sorted { $0.timestamp > $1.timestamp }
            )
        }
    }

    private func dayLabel(for date: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(date) { return "today" }
        if calendar.isDateInYesterday(date) { return "yesterday" }
        return date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)).lowercased()
    }
}

// MARK: - Day label

private struct DayLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.jetbrainsMono(size: 10))
            .foregroundStyle(Color.relayFaint)
            .tracking(1.2)
            .textCase(.uppercase)
            .padding(.top, 20)
            .padding(.bottom, 4)
            .padding(.horizontal, RelaySpacing.screenH)
    }
}

// MARK: - Capture row

private struct CaptureRowView: View {
    let capture: Capture

    private var timeLabel: String {
        capture.timestamp.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(timeLabel)
                .font(.jetbrainsMono(size: 10.5))
                .foregroundStyle(Color.relayFaint)
                .tracking(0.4)
                .frame(width: 38, alignment: .leading)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 6) {
                Text(capture.transcript)
                    .font(.newsreader(size: 16))
                    .foregroundStyle(Color.relayInk)
                    .tracking(-0.1)
                    .lineSpacing(3)

                if let reply = capture.reply {
                    replyBlock(reply)
                }

                statusTag
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, RelaySpacing.screenH)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.relayHair)
                .frame(height: RelaySpacing.hairline)
                .padding(.leading, RelaySpacing.screenH + 52)
        }
    }

    @ViewBuilder
    private func replyBlock(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "arrow.turn.down.right")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.relaySage)
                .padding(.top, 3)
            Text(text)
                .font(.newsreader(size: 15, italic: true))
                .foregroundStyle(Color.relayMuted)
                .tracking(-0.1)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    private var statusTag: some View {
        switch capture.status {
        case .queued:
            Text("queued · local")
                .font(.jetbrainsMono(size: 10))
                .foregroundStyle(Color.relayFaint)
                .tracking(0.4)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.relayHair2, lineWidth: RelaySpacing.hairline)
                )
        case .sent:
            Text("sent")
                .font(.jetbrainsMono(size: 10))
                .foregroundStyle(Color.relaySage)
                .tracking(0.4)
        case .failed:
            Text("failed · retry?")
                .font(.jetbrainsMono(size: 10))
                .foregroundStyle(Color.relayRust)
                .tracking(0.4)
        }
    }
}

// MARK: - Hold to speak

private struct HoldToSpeakButton: View {
    @Environment(CaptureViewModel.self) private var captureVM
    @GestureState private var isHolding: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: RelaySpacing.buttonRadius)
                    .fill(Color.relayInk)
                    .frame(height: RelaySpacing.buttonHeight)
                    .shadow(color: .black.opacity(0.35), radius: 20, y: 10)

                HStack(spacing: 12) {
                    Image(systemName: "mic")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.relayOnInk)
                    Text("hold to speak")
                        .font(.relaySans(size: 16, weight: .medium))
                        .foregroundStyle(Color.relayOnInk)
                        .tracking(-0.1)
                }
            }
            .scaleEffect(isHolding ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isHolding)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isHolding) { _, state, _ in state = true }
                    .onChanged { _ in
                        if case .idle = captureVM.state { captureVM.startCapture() }
                    }
                    .onEnded { _ in captureVM.stopCapture() }
            )

            Text("or press AirPods stem")
                .font(.jetbrainsMono(size: 10))
                .foregroundStyle(Color.relayFaint)
                .tracking(0.3)
        }
    }
}

#Preview {
    let store = CaptureStore()
    store.add(Capture(
        id: UUID(),
        timestamp: .now,
        transcript: "Mit Jan über das Pairing reden, vielleicht ein QR-Flow statt Shared Secret.",
        status: .sent,
        durationSeconds: 4.2,
        reply: "Notiert. Ich habe eine Aufgabe für das QR-Pairing in deiner Inbox angelegt."
    ))
    store.add(Capture(
        id: UUID(),
        timestamp: Date(timeIntervalSinceNow: -3600),
        transcript: "Annie Dillard, das Buch aus dem Podcast — kommt mit auf die Leseliste.",
        status: .queued,
        durationSeconds: 2.8
    ))

    let speech = SpeechTranscriptionService()
    let captureVM = CaptureViewModel(speech: speech, store: store)

    return HomeView()
        .environment(captureVM)
        .environment(store)
}
