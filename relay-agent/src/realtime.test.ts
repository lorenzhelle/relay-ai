import { describe, expect, test } from "bun:test";
import type { CaptureMetadata, InputChannel } from "./input-channel.js";

// config.ts calls process.exit(1) when these are unset, so set them before the
// dynamic import of the module under test. The values are never dialed — routeCapture
// is pure and the supabase client only connects on subscribe().
process.env.SUPABASE_URL ??= "http://localhost:54321";
process.env.SUPABASE_ANON_KEY ??= "test-anon-key";

const { routeCapture } = await import("./realtime.js");
const { AgentSdkChannel } = await import("./input-channel.js");

/** Records everything sent through it so tests can assert on the routed transcript. */
class MockChannel implements InputChannel {
  sent: Array<{ transcript: string; meta: CaptureMetadata }> = [];
  send(transcript: string, meta: CaptureMetadata): void {
    this.sent.push({ transcript, meta });
  }
}

describe("routeCapture", () => {
  test("forwards a valid capture to the input channel with its captureId", () => {
    const channel = new MockChannel();
    const outbound: object[] = [];

    const routed = routeCapture(
      {
        type: "capture",
        transcript: "remind me to call Jan",
        clientCaptureId: "ABC-123",
        durationSeconds: 4.2,
        timestamp: "2026-06-10T10:00:00Z",
      },
      channel,
      (p) => outbound.push(p),
    );

    expect(routed).toBe(true);
    expect(channel.sent).toHaveLength(1);
    expect(channel.sent[0]!.transcript).toBe("remind me to call Jan");
    // captureId must survive the trip so the agent's reply can be matched to it.
    expect(channel.sent[0]!.meta.captureId).toBe("ABC-123");
  });

  test("acks back to iOS with the same captureId", () => {
    const channel = new MockChannel();
    const outbound: any[] = [];

    routeCapture(
      { type: "capture", transcript: "hi", clientCaptureId: "XYZ-9" },
      channel,
      (p) => outbound.push(p),
    );

    expect(outbound).toEqual([{ type: "ack", clientCaptureId: "XYZ-9" }]);
  });

  test("ignores non-capture and empty payloads", () => {
    const channel = new MockChannel();
    const outbound: object[] = [];
    const send = (p: object) => outbound.push(p);

    expect(routeCapture(null, channel, send)).toBe(false);
    expect(routeCapture({ type: "other" }, channel, send)).toBe(false);
    expect(routeCapture({ type: "capture", transcript: "" }, channel, send)).toBe(false);

    expect(channel.sent).toHaveLength(0);
    expect(outbound).toHaveLength(0);
  });
});

describe("AgentSdkChannel — inbound path to the agent loop", () => {
  test("a routed capture surfaces in messages() with its captureId", async () => {
    const channel = new AgentSdkChannel();

    // Simulate Supabase delivering a capture broadcast.
    routeCapture(
      { type: "capture", transcript: "what's on my calendar?", clientCaptureId: "CAP-1" },
      channel,
      () => {},
    );

    const iterator = channel.messages();
    const { value } = await iterator.next();

    expect(value.transcript).toBe("what's on my calendar?");
    expect(value.meta.captureId).toBe("CAP-1"); // the agent reads this for its reply
  });
});
