/**
 * relay-agent — MCP server that bridges Claude Code with the Relay iOS app.
 *
 * Boot sequence:
 *   1. Load config & generate a pairing code
 *   2. Select input channel (agent-sdk or mcp, via RELAY_CHANNEL_MODE env var)
 *   3. Connect the MCP server over stdio
 *   4. Register the pairing code in Supabase
 *   5. Open Supabase Realtime channels (inbound captures + outbound replies)
 *   6. Start the agent loop (agent-sdk mode only)
 *
 * To switch back to the MCP notifications channel approach:
 *   RELAY_CHANNEL_MODE=mcp bun run index.ts
 */

import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

import { generateCode, loadOrCreateChannelId } from "./src/config.js";
import { registerPairingCode } from "./src/supabase.js";
import { mcp, registerToolHandlers, setSendToIos } from "./src/mcp.js";
import { initRealtime, sendToIos, subscribeToCaptures } from "./src/realtime.js";
import {
  AgentSdkChannel,
  McpNotificationChannel,
  type InputChannel,
} from "./src/input-channel.js";
import { runAgentLoop } from "./src/agent.js";

// ─── Identity ─────────────────────────────────────────────────────────────────

const channelId = loadOrCreateChannelId();
const pairingCode = generateCode();

// ─── Input channel selection ──────────────────────────────────────────────────

const CHANNEL_MODE = process.env.RELAY_CHANNEL_MODE ?? "agent-sdk";
let inputChannel: InputChannel;

if (CHANNEL_MODE === "mcp") {
  // Legacy path: re-enables notifications/claude/channel when Claude Code fixes
  // channel support. Preserved in McpNotificationChannel with zero code changes.
  console.error("[relay-agent] channel mode: mcp (legacy notifications)");
  const mcpChannel = new McpNotificationChannel();
  mcpChannel.setServer(mcp);
  inputChannel = mcpChannel;
} else {
  // Default: Agent SDK path — each transcript becomes a query() session.
  console.error("[relay-agent] channel mode: agent-sdk");
  inputChannel = new AgentSdkChannel();
}

// ─── Wire up cross-module dependencies ───────────────────────────────────────

// Give the MCP tool handler a way to send messages to iOS
setSendToIos(sendToIos);

// Give Realtime the active InputChannel so it routes captures correctly
initRealtime(pairingCode, inputChannel);

// Register tool handlers with the runtime pairing code + channel ID
registerToolHandlers(channelId, pairingCode);

// ─── Boot ─────────────────────────────────────────────────────────────────────

const transport = new StdioServerTransport();
await mcp.connect(transport);

await registerPairingCode(channelId, pairingCode);
subscribeToCaptures(channelId);

console.error(`[relay-agent] ready · pairing code: ${pairingCode}`);

// ─── MCP notification startup announcement (legacy path only) ─────────────────

if (CHANNEL_MODE === "mcp") {
  // Announce pairing code into Claude's context via the channel mechanism.
  // In agent-sdk mode the pairing code is visible via get_pairing_info.
  (inputChannel as McpNotificationChannel).announce(pairingCode);
}

// ─── Start agent loop (agent-sdk mode only) ───────────────────────────────────

if (CHANNEL_MODE !== "mcp") {
  // runAgentLoop runs forever — we do NOT await it here so the MCP server
  // keeps processing tool calls on the main thread concurrently.
  runAgentLoop({
    channel: inputChannel as AgentSdkChannel,
    channelId,
    pairingCode,
    sendToIos,
  }).catch((err) => {
    console.error("[relay-agent] agent loop fatal error:", err);
    process.exit(1);
  });
}
