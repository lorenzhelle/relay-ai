import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { SUPABASE_URL, CODE_EXPIRES_MIN } from "./config.js";

// ─── Server ───────────────────────────────────────────────────────────────────

export const mcp = new Server(
  { name: "relay", version: "1.0.0" },
  {
    capabilities: {
      experimental: { "claude/channel": {} },
      tools: {},
    },
    instructions:
      'Voice transcripts from the Relay iOS app arrive as <channel source="relay" ...> events. ' +
      "Each event is a voice note transcription the user recorded on their phone. " +
      "Process and respond to them naturally. " +
      "Use the reply tool to send a message back to the user's phone.",
  },
);

// ─── Tool: reply ──────────────────────────────────────────────────────────────

/**
 * Called by the MCP tool handler to send a speak event.
 * Injected at registration time so the handler doesn't need a global.
 */
let _sendToIos: (payload: object) => void = () => {};

export function setSendToIos(fn: (payload: object) => void): void {
  _sendToIos = fn;
}

// ─── Tool definitions ─────────────────────────────────────────────────────────

mcp.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "reply",
      description:
        "Send a text message back to the user's iOS Relay app. They will see it on their phone.",
      inputSchema: {
        type: "object",
        properties: {
          message: { type: "string", description: "The reply text to send." },
        },
        required: ["message"],
      },
    },
    {
      name: "get_pairing_info",
      description:
        "Get the current pairing code so a user can pair their iOS device with this plugin.",
      inputSchema: { type: "object", properties: {} },
    },
  ],
}));

// ─── Tool handlers ────────────────────────────────────────────────────────────

export function registerToolHandlers(
  channelId: string,
  pairingCode: string,
): void {
  mcp.setRequestHandler(CallToolRequestSchema, async (request) => {
    switch (request.params.name) {
      case "reply": {
        const message = String(request.params.arguments?.message ?? "");
        // SpeakEvent — iOS reads this aloud via AVSpeech
        _sendToIos({ type: "speak", text: message });
        return { content: [{ type: "text", text: `Reply sent: "${message}"` }] };
      }

      case "get_pairing_info": {
        const projectUrl = SUPABASE_URL!.replace(/\/$/, "");
        return {
          content: [
            {
              type: "text",
              text:
                `Relay channel info:\n` +
                `  Supabase project: ${projectUrl}\n` +
                `  Pairing code: ${pairingCode}\n` +
                `  Channel ID: ${channelId}\n\n` +
                `Open the iOS Relay app → tap "Connect" → enter the pairing code above.\n` +
                `The code expires ${CODE_EXPIRES_MIN} minutes after the plugin started.`,
            },
          ],
        };
      }

      default:
        throw new Error(`Unknown tool: ${request.params.name}`);
    }
  });
}

// ─── Startup announcement ─────────────────────────────────────────────────────

let announced = false;

/**
 * Sends a one-time system notification to Claude so the pairing code
 * appears in context immediately on startup.
 */
export function announceToClaudeOnce(pairingCode: string): void {
  if (announced) return;
  announced = true;
  mcp
    .notification({
      method: "notifications/claude/channel",
      params: {
        content:
          `Relay channel ready · pairing code: ${pairingCode} · ` +
          `ask me "how do I pair my phone?" for setup details`,
        meta: { type: "system", event: "startup" },
      },
    })
    .catch(() => {});
}

// ─── Channel event helpers ────────────────────────────────────────────────────

/** Forwards a voice transcript from iOS to Claude as a channel event. */
export function forwardCaptureToClaude(payload: {
  transcript: string;
  clientCaptureId?: string;
  durationSeconds?: number;
  timestamp?: string;
}): void {
  const { transcript, clientCaptureId, durationSeconds, timestamp } = payload;

  mcp
    .notification({
      method: "notifications/claude/channel",
      params: {
        content: transcript,
        meta: {
          captureId: clientCaptureId ?? "",
          duration: String(durationSeconds ?? ""),
          timestamp: timestamp ?? new Date().toISOString(),
        },
      },
    })
    .catch(() => {});
}
