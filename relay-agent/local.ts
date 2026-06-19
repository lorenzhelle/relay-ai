/**
 * Local test mode — run the agent loop without Supabase or an iOS device.
 * Type a message and press Enter; the agent processes it and prints its reply.
 *
 *   bun run local
 */

import { createInterface } from "readline";
import { AgentSdkChannel } from "./src/input-channel.js";
import { runAgentLoop } from "./src/agent.js";

const channel = new AgentSdkChannel();

function sendToLocal(payload: object) {
  const p = payload as { type: string; text?: string };
  if (p.type === "speak" && p.text) {
    process.stdout.write(`\n[agent] ${p.text}\n\n> `);
  }
}

const rl = createInterface({ input: process.stdin, terminal: false });

process.stdout.write("[relay-agent] local test mode\n> ");

rl.on("line", (line) => {
  const transcript = line.trim();
  if (transcript) channel.send(transcript, {});
});

rl.on("close", () => process.exit(0));

await runAgentLoop({ channel, sendToIos: sendToLocal });
