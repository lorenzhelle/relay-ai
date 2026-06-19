import { query } from "@anthropic-ai/claude-agent-sdk";
import type { AgentSdkChannel } from "./input-channel.js";

// ─── System prompt ────────────────────────────────────────────────────────────

function buildSystemPrompt(voiceReply: boolean): string {
  if (voiceReply) {
    return `\
You are the voice assistant for the Relay iOS app. Voice transcripts from the
user's iPhone arrive as user messages.

Your response will be read aloud via text-to-speech. Keep it short and
conversational — one or two sentences. No markdown, no lists, no raw IDs or
tool output. Complete tasks silently and only surface what the user needs to
hear.`;
  }
  return `\
You are the assistant for the Relay iOS app. Transcripts from the user's
iPhone arrive as user messages.

Complete the task and respond with a clear, concise summary. You may use
markdown. Do not include raw tool output or IDs unless specifically asked.`;
}

// ─── Agent runner ─────────────────────────────────────────────────────────────

export interface AgentRunnerOptions {
  channel: AgentSdkChannel;
  sendToIos: (payload: object) => void;
}

/**
 * Starts a long-running loop that:
 *   1. Waits for a voice transcript from AgentSdkChannel.messages()
 *   2. Runs a query() session with the transcript as the user prompt
 *   3. Captures the last assistant text and pushes it back to iOS
 *   4. Repeats for every subsequent transcript
 */
export async function runAgentLoop(opts: AgentRunnerOptions): Promise<never> {
  const { channel, sendToIos } = opts;

  for await (const { transcript, meta } of channel.messages()) {
    const voiceReply = meta.voiceReply !== false; // default true
    console.error(
      `[relay-agent] agent processing: "${transcript.slice(0, 60)}${transcript.length > 60 ? "..." : ""}" (voice reply: ${voiceReply})`,
    );

    try {
      let lastAssistantText: string | undefined;

      for await (const message of query({
        prompt: transcript,
        options: {
          systemPrompt: buildSystemPrompt(voiceReply),
          permissionMode: "default",
          maxTurns: 10,
        },
      })) {
        // Collect text from the last assistant message
        if (message.type === "assistant") {
          const content = (message as any).message?.content;
          if (Array.isArray(content)) {
            const text = content
              .filter((b: any) => b.type === "text")
              .map((b: any) => b.text as string)
              .join("")
              .trim();
            if (text) lastAssistantText = text;
          }
        }
        if (message.type === "result") {
          console.info(
            `[relay-agent] turn complete (${(message as { num_turns?: number }).num_turns ?? "?"} turns)`,
          );
        }
      }

      // Push the final response back to iOS
      if (lastAssistantText) {
        sendToIos({
          type: voiceReply ? "speak" : "text",
          text: lastAssistantText,
          clientCaptureId: meta.captureId,
        });
      }
    } catch (err) {
      console.error("[relay-agent] agent error:", err);
      // Continue the loop — one failed turn must not crash the process.
    }
  }

  // Unreachable: channel.messages() is an infinite generator.
  throw new Error("agent loop exited unexpectedly");
}
