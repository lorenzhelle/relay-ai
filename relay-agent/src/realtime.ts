import { type RealtimeChannel } from "@supabase/supabase-js";
import { supabase } from "./supabase.js";
import type { InputChannel } from "./input-channel.js";

// ─── Channel name ─────────────────────────────────────────────────────────────

function channelName(channelId: string): string {
  return `relay:${channelId}`;
}

// ─── Outbound (plugin → iOS) ──────────────────────────────────────────────────

let outboundChannel: RealtimeChannel | null = null;

/** Broadcasts a payload to the iOS app (ack, speak, etc.). */
export function sendToIos(payload: object): void {
  outboundChannel?.send({ type: "broadcast", event: "message", payload });
}

// ─── Subscription setup ───────────────────────────────────────────────────────

/** CaptureEvent sent by the iOS app after a voice recording is transcribed. */
export interface CapturePayload {
  type: "capture";
  transcript: string;
  clientCaptureId: string;
  durationSeconds?: number;
  timestamp?: string;
  /** When false, the agent should work silently without sending a spoken reply. Defaults to true. */
  voiceReply?: boolean;
}

/**
 * Pure routing logic for an inbound broadcast payload from the iOS app:
 *   - validates it's a non-empty capture
 *   - forwards the transcript to the active InputChannel (→ Claude agent)
 *   - acks back to iOS so the app can mark the capture as delivered
 *
 * Returns true when the payload was a valid capture that got routed, false
 * otherwise. Extracted from subscribeToCaptures so it can be unit-tested
 * without a live Supabase connection.
 */
export function routeCapture(
  payload: unknown,
  inputChannel: InputChannel,
  send: (p: object) => void,
): boolean {
  const p = payload as Partial<CapturePayload> | null;
  if (!p || p.type !== "capture" || !p.transcript) return false;

  inputChannel.send(p.transcript, {
    captureId: p.clientCaptureId,
    duration: String(p.durationSeconds ?? ""),
    timestamp: p.timestamp ?? new Date().toISOString(),
    voiceReply: p.voiceReply !== false, // default true
  });

  send({ type: "ack", clientCaptureId: p.clientCaptureId });
  return true;
}

/**
 * Opens a single Supabase Realtime broadcast channel shared by iOS and the
 * agent. iOS sends `capture` events; the agent sends `ack`, `speak`, and
 * `text` events. Supabase does not echo your own broadcasts back to you, so
 * both sides can safely share one channel without creating loops.
 */
export function subscribeToCaptures(channelId: string, channel: InputChannel): void {
  const name = channelName(channelId);

  outboundChannel = supabase
    .channel(name)
    .on("broadcast", { event: "message" }, ({ payload }) => {
      const transcript = (payload as Partial<CapturePayload>)?.transcript;
      if (transcript) {
        console.error(
          `[relay-agent] capture received: "${transcript.slice(0, 60)}${transcript.length > 60 ? "..." : ""}"`,
        );
      }
      routeCapture(payload, channel, sendToIos);
    })
    .subscribe((status) => {
      if (status === "SUBSCRIBED") {
        console.error(`[relay-agent] channel ready: ${name}`);
      }
    });
}
