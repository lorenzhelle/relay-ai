//
//  relayTests.swift
//  relayTests
//
//  Created by Lorenz Helle on 09.04.26.
//

import Testing
import Foundation
@testable import relay

@MainActor
struct CaptureStoreTests {

    private func makeCapture(_ transcript: String, status: CaptureStatus = .queued) -> Capture {
        Capture(
            id: UUID(),
            timestamp: .now,
            transcript: transcript,
            status: status,
            durationSeconds: 1.0
        )
    }

    @Test func addInsertsNewestFirst() {
        let store = CaptureStore()
        let first = makeCapture("one")
        let second = makeCapture("two")
        store.add(first)
        store.add(second)

        #expect(store.captures.map(\.transcript) == ["two", "one"])
    }

    @Test func updateStatusMarksMatchingCaptureSent() {
        let store = CaptureStore()
        let capture = makeCapture("hello")
        store.add(capture)

        store.updateStatus(of: capture.id, to: .sent)

        #expect(store.captures.first?.status == .sent)
    }

    @Test func setReplyAttachesToMatchingCaptureAndMarksSent() {
        let store = CaptureStore()
        let older = makeCapture("older")
        let target = makeCapture("target")
        store.add(older)
        store.add(target)

        store.setReply("here is your answer", for: target.id)

        let updated = store.captures.first { $0.id == target.id }
        #expect(updated?.reply == "here is your answer")
        #expect(updated?.status == .sent)
        // The unrelated capture is untouched.
        #expect(store.captures.first { $0.id == older.id }?.reply == nil)
    }

    @Test func setReplyWithNilIdFallsBackToMostRecentCapture() {
        let store = CaptureStore()
        store.add(makeCapture("old"))
        store.add(makeCapture("newest"))

        store.setReply("reply without id", for: nil)

        // captures are newest-first, so index 0 is the most recent capture.
        #expect(store.captures.first?.reply == "reply without id")
        #expect(store.captures.last?.reply == nil)
    }

    @Test func setReplyWithUnknownIdFallsBackToMostRecentCapture() {
        let store = CaptureStore()
        store.add(makeCapture("recent"))

        store.setReply("orphan reply", for: UUID())

        #expect(store.captures.first?.reply == "orphan reply")
    }
}
