import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { SUPABASE_URL, CODE_EXPIRES_MIN } from "./config.js";

// NOTE: forwardCaptureToClaude() and announceToClaudeOnce() have been moved to
// McpNotificationChannel in src/input-channel.ts. They are preserved there and
// re-enabled via RELAY_CHANNEL_MODE=mcp.

// ─── Server ───────────────────────────────────────────────────────────────────

export const mcp = new Server(
  { name: "relay", version: "1.0.0" },
  {
    capabilities: {
      // Keep the channel capability declared so the MCP server still advertises
      // it correctly for future channel support.
      experimental: { "claude/channel": {} },
      tools: {},
    },
    instructions:
      "You are the Relay voice bridge. The user's voice transcripts are processed " +
      "via the Agent SDK. Use the reply tool to speak back to the user's phone.",
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
