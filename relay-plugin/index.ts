import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { createClient, type RealtimeChannel } from "@supabase/supabase-js";
import { readFileSync, writeFileSync, existsSync } from "fs";
import { join } from "path";

// ─── Config ───────────────────────────────────────────────────────────────────

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error(
    "[relay-plugin] SUPABASE_URL and SUPABASE_ANON_KEY must be set.\n" +
    "Copy relay-plugin/.env.example → relay-plugin/.env and fill in your project values."
  );
  process.exit(1);
}

// ─── Persistent channel identity ─────────────────────────────────────────────

const CHANNEL_ID_PATH = join(import.meta.dir, ".channel-id");
const CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

function loadOrCreateChannelId(): string {
  if (existsSync(CHANNEL_ID_PATH)) {
    return readFileSync(CHANNEL_ID_PATH, "utf8").trim();
  }
  const id = crypto.randomUUID();
  writeFileSync(CHANNEL_ID_PATH, id, "utf8");
  return id;
}

function generateCode(): string {
  return Array.from(
    { length: 6 },
    () => CODE_CHARS[Math.floor(Math.random() * CODE_CHARS.length)]
  ).join("");
}

const channelId = loadOrCreateChannelId();
const pairingCode = generateCode();
const CODE_EXPIRES_MIN = 10;

// ─── Supabase client ──────────────────────────────────────────────────────────

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  realtime: { params: { eventsPerSecond: 10 } },
});

// Register this plugin's pairing code in Supabase so the pair Edge Function
// can validate it when the iOS app submits a pairing code.
async function registerPairingCode(): Promise<void> {
  const expiresAt = new Date(
    Date.now() + CODE_EXPIRES_MIN * 60 * 1000
  ).toISOString();

  const { error } = await supabase.from("sessions").upsert(
    {
      channel_id: channelId,
      pairing_code: pairingCode,
      code_expires_at: expiresAt,
      last_seen: new Date().toISOString(),
    },
    { onConflict: "channel_id" }
  );

  if (error) {
    console.error("[relay-plugin] failed to register pairing code:", error.message);
  } else {
    console.error(
      `[relay-plugin] registered pairing code ${pairingCode} (expires in ${CODE_EXPIRES_MIN}m)`
    );
  }
}

// ─── Broadcast channels ───────────────────────────────────────────────────────

const IOS_TO_PLUGIN_CHANNEL = `relay:${channelId}:ios-to-plugin`;
const PLUGIN_TO_IOS_CHANNEL = `relay:${channelId}:plugin-to-ios`;

let outboundChannel: RealtimeChannel | null = null;

function sendToIos(payload: object): void {
  if (!outboundChannel) return;
  outboundChannel.send({
    type: "broadcast",
    event: "message",
    payload,
  });
}

// ─── MCP server ───────────────────────────────────────────────────────────────

const mcp = new Server(
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
  }
);

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

mcp.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (request.params.name === "reply") {
    const message = String(request.params.arguments?.message ?? "");
    // SpeakEvent — iOS will read this aloud via AVSpeech
    sendToIos({ type: "speak", text: message });
    return { content: [{ type: "text", text: `Reply sent: "${message}"` }] };
  }

  if (request.params.name === "get_pairing_info") {
    const projectUrl = SUPABASE_URL.replace(/\/$/, "");
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

  throw new Error(`Unknown tool: ${request.params.name}`);
});

// ─── Supabase Realtime subscription ──────────────────────────────────────────

function subscribeToCaptures(): void {
  // Outbound: plugin → iOS (ack, speak)
  outboundChannel = supabase.channel(PLUGIN_TO_IOS_CHANNEL);
  outboundChannel.subscribe((status) => {
    if (status === "SUBSCRIBED") {
      console.error(`[relay-plugin] publishing replies on ${PLUGIN_TO_IOS_CHANNEL}`);
    }
  });

  // Inbound: iOS → plugin (capture)
  const inboundChannel = supabase.channel(IOS_TO_PLUGIN_CHANNEL);
  inboundChannel
    .on("broadcast", { event: "message" }, ({ payload }) => {
      if (!payload || payload.type !== "capture") return;

      const {
        transcript,
        clientCaptureId,
        durationSeconds,
        timestamp,
      } = payload as {
        transcript: string;
        clientCaptureId: string;
        durationSeconds?: number;
        timestamp?: string;
      };

      if (!transcript) return;

      console.error(
        `[relay-plugin] capture received: "${transcript.slice(0, 60)}${transcript.length > 60 ? "..." : ""}"`
      );

      // Forward to Claude Code as a channel event
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

      // Immediately ack back to iOS
      sendToIos({ type: "ack", clientCaptureId });
    })
    .subscribe((status) => {
      if (status === "SUBSCRIBED") {
        console.error(`[relay-plugin] listening on ${IOS_TO_PLUGIN_CHANNEL}`);
        announceToClaudeOnce();
      }
    });
}

// ─── Startup announcement ─────────────────────────────────────────────────────

let announced = false;
function announceToClaudeOnce(): void {
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

// ─── Boot ─────────────────────────────────────────────────────────────────────

const transport = new StdioServerTransport();
await mcp.connect(transport);

await registerPairingCode();
subscribeToCaptures();
