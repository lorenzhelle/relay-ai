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
interface CapturePayload {
  type: "capture";
  transcript: string;
  clientCaptureId: string;
  durationSeconds?: number;
  timestamp?: string;
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
      if (!payload || payload.type !== "capture") return;

      const { transcript, clientCaptureId, durationSeconds, timestamp } =
        payload as CapturePayload;

      if (!transcript) return;

      console.error(
        `[relay-agent] capture received: "${transcript.slice(0, 60)}${transcript.length > 60 ? "..." : ""}"`,
      );

      // Forward transcript to whichever InputChannel is active (AgentSdkChannel
      // or McpNotificationChannel, depending on RELAY_CHANNEL_MODE).
      _inputChannel?.send(transcript, {
        captureId: clientCaptureId,
        duration: String(durationSeconds ?? ""),
        timestamp: timestamp ?? new Date().toISOString(),
      });

      // Immediately ack so the iOS app knows the message was received
      sendToIos({ type: "ack", clientCaptureId });
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
