import {
  query,
  createSdkMcpServer,
  tool,
} from "@anthropic-ai/claude-agent-sdk";
import { z } from "zod";
import type { AgentSdkChannel } from "./input-channel.js";
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
  sendToIos: (payload: object) => void;
}

/**
 * Starts a long-running loop that:
 *   1. Waits for a voice transcript from AgentSdkChannel.messages()
 *   2. Runs a query() session with the transcript as the user prompt
 *   3. Repeats for every subsequent transcript
 *
 * Each transcript gets its own independent query() call. The reply tool is
 * served via an in-process MCP server built once and reused across all calls.
 */
export async function runAgentLoop(opts: AgentRunnerOptions): Promise<never> {
  const { channel, sendToIos } = opts;

  // The capture currently being processed. Set before each query() and read by
  // the reply tool so the spoken reply can be matched back to its capture on iOS.
  // Safe because the transcript loop processes one query() at a time.
  let currentCaptureId: string | undefined;

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
        {
          message: z
            .string()
            .describe("The reply text. One or two short sentences."),
        },
        async ({ message }) => {
          // Fire-and-forget: broadcast to iOS without awaiting TTS or ack.
          // Include the capture id so the iOS app can attach the reply to the
          // capture that prompted it.
          sendToIos({
            type: "speak",
            text: message,
            clientCaptureId: currentCaptureId,
          });
          return {
            content: [{ type: "text", text: `Reply sent: "${message}"` }],
          };
        },
      ),
    ],
  });

  // ─── Transcript loop ───────────────────────────────────────────────────────

  for await (const { transcript, meta } of channel.messages()) {
    currentCaptureId = meta.captureId;
    const voiceReply = meta.voiceReply !== false; // default true
    console.error(
      `[relay-agent] agent processing: "${transcript.slice(0, 60)}${transcript.length > 60 ? "..." : ""}" (voice reply: ${voiceReply})`,
    );

    // Build a system prompt variant that tells the agent to stay silent when
    // the user has disabled voice replies.
    const systemPrompt = voiceReply
      ? SYSTEM_PROMPT
      : SYSTEM_PROMPT +
        "\n\n<output_mode>Text-only mode is active. Do NOT call reply — work silently and complete the task without any spoken output.</output_mode>";

    try {
      for await (const message of query({
        prompt: transcript,
        options: {
          systemPrompt,
          mcpServers: { relay: relayServer },
          // Pre-approve relay tools so Claude can call them without a permission prompt.
          // MCP tool names follow the pattern mcp__{serverName}__{toolName}.
          // In text-only mode the reply tool is still available but the system prompt
          // instructs the agent not to call it.
          allowedTools: voiceReply ? ["mcp__relay__reply"] : [],
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
