import { query, createSdkMcpServer, tool } from "@anthropic-ai/claude-agent-sdk";
import { z } from "zod";
import type { AgentSdkChannel } from "./input-channel.js";
import { SUPABASE_URL, CODE_EXPIRES_MIN } from "./config.js";

// ─── System prompt ────────────────────────────────────────────────────────────

const SYSTEM_PROMPT = `\
You are the voice assistant for the Relay iOS app. Voice transcripts from the
user's iPhone arrive as user messages.

<voice_policy>
Operate silently by default. Call reply only when:
  - You need the user's input, a decision, or a confirmation to continue.
  - You have a result the user explicitly asked to be told about, or you are done.
Never call reply for: intermediate steps, tool-by-tool narration, or filler.
When you do speak: one or two short, conversational sentences. No markdown,
no IDs, no raw tool output. Ask at most one question at a time.
</voice_policy>

When you don't need to reply, end your turn silently after completing the task.`;

// ─── Agent runner ─────────────────────────────────────────────────────────────

export interface AgentRunnerOptions {
  channel: AgentSdkChannel;
  channelId: string;
  pairingCode: string;
  /** Injected by index.ts; called by the reply tool handler. */
  sendToIos: (payload: object) => void;
}

/**
 * Starts a long-running loop that:
 *   1. Waits for a voice transcript from AgentSdkChannel.messages()
 *   2. Runs a query() session with the transcript as the user prompt
 *   3. Repeats for every subsequent transcript
 *
 * Each transcript gets its own independent query() call. The reply and
 * get_pairing_info tools are served via an in-process MCP server.
 *
 * The relayServer is built once and reused across all query() calls.
 */
export async function runAgentLoop(opts: AgentRunnerOptions): Promise<never> {
  const { channel, channelId, pairingCode, sendToIos } = opts;

  // ─── In-process MCP server with relay tools ───────────────────────────────

  const relayServer = createSdkMcpServer({
    name: "relay",
    version: "1.0.0",
    alwaysLoad: true, // never defer behind tool search; tools always in context
    tools: [
      // ── reply ──────────────────────────────────────────────────────────────
      tool(
        "reply",
        "Send a text message back to the user's iOS Relay app. They will hear it " +
          "spoken aloud via text-to-speech. Use only when you have a result the " +
          "user asked to be told about, or need their input.",
        { message: z.string().describe("The reply text. One or two short sentences.") },
        async ({ message }) => {
          // Fire-and-forget: broadcast to iOS without awaiting TTS or ack.
          sendToIos({ type: "speak", text: message });
          return { content: [{ type: "text", text: `Reply sent: "${message}"` }] };
        },
      ),

      // ── get_pairing_info ───────────────────────────────────────────────────
      tool(
        "get_pairing_info",
        "Get the current pairing code so a user can pair their iOS device with this plugin.",
        {},
        async () => {
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
        },
      ),
    ],
  });

  // ─── Transcript loop ───────────────────────────────────────────────────────

  for await (const { transcript } of channel.messages()) {
    console.error(
      `[relay-agent] agent processing: "${transcript.slice(0, 60)}${transcript.length > 60 ? "..." : ""}"`,
    );

    try {
      for await (const message of query({
        prompt: transcript,
        options: {
          systemPrompt: SYSTEM_PROMPT,
          mcpServers: { relay: relayServer },
          // Pre-approve relay tools so Claude can call them without a permission prompt.
          // MCP tool names follow the pattern mcp__{serverName}__{toolName}.
          allowedTools: ["mcp__relay__reply", "mcp__relay__get_pairing_info"],
          permissionMode: "default",
          maxTurns: 10,
        },
      })) {
        if (message.type === "result") {
          console.error(
            `[relay-agent] turn complete (${(message as { num_turns?: number }).num_turns ?? "?"} turns)`,
          );
        }
      }
    } catch (err) {
      console.error("[relay-agent] agent error:", err);
      // Continue the loop — one failed turn must not crash the process.
    }
  }

  // Unreachable: channel.messages() is an infinite generator.
  throw new Error("agent loop exited unexpectedly");
}
