import { type RealtimeChannel } from "@supabase/supabase-js";
import { supabase } from "./supabase.js";
import type { InputChannel } from "./input-channel.js";

// ─── Channel names ────────────────────────────────────────────────────────────

function channelNames(channelId: string) {
  return {
    iosToPlugin: `relay:${channelId}:ios-to-plugin`,
    pluginToIos: `relay:${channelId}:plugin-to-ios`,
  };
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
  });

  send({ type: "ack", clientCaptureId: p.clientCaptureId });
  return true;
}

/**
 * Opens the two Supabase Realtime broadcast channels:
 *   - outbound (`plugin-to-ios`): ack and speak messages → iOS
 *   - inbound  (`ios-to-plugin`): voice capture events ← iOS
 */
export function subscribeToCaptures(channelId: string): void {
  const { iosToPlugin, pluginToIos } = channelNames(channelId);

  // Outbound channel — subscribe first so it's ready before we receive captures
  outboundChannel = supabase.channel(pluginToIos);
  outboundChannel.subscribe((status) => {
    if (status === "SUBSCRIBED") {
      console.error(`[relay-agent] publishing replies on ${pluginToIos}`);
    }
  });

  // Inbound channel — receives voice transcripts from the iOS app
  supabase
    .channel(iosToPlugin)
    .on("broadcast", { event: "message" }, ({ payload }) => {
      if (!_inputChannel) return;

      const transcript = (payload as Partial<CapturePayload>)?.transcript;
      if (transcript) {
        console.error(
          `[relay-agent] capture received: "${transcript.slice(0, 60)}${transcript.length > 60 ? "..." : ""}"`,
        );
      }

      // Forward to the active InputChannel and ack back to iOS (pure logic in
      // routeCapture so it can be unit-tested without a live connection).
      routeCapture(payload, _inputChannel, sendToIos);
    })
    .subscribe((status) => {
      if (status === "SUBSCRIBED") {
        console.error(`[relay-agent] listening on ${iosToPlugin}`);
        // Startup announcement in MCP mode is handled by index.ts via
        // McpNotificationChannel.announce(). No action needed here.
      }
    });
}

// ─── Init ─────────────────────────────────────────────────────────────────────

let _pairingCode = "";
let _inputChannel: InputChannel | null = null;

/** Must be called before subscribeToCaptures. */
export function initRealtime(pairingCode: string, inputChannel: InputChannel): void {
  _pairingCode = pairingCode;
  _inputChannel = inputChannel;
}
