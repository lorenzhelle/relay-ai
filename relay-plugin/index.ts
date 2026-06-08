/**
 * relay-plugin — MCP server that bridges Claude Code with the Relay iOS app.
 *
 * Boot sequence:
 *   1. Load config & generate a pairing code
 *   2. Connect the MCP server over stdio
 *   3. Register the pairing code in Supabase
 *   4. Open Supabase Realtime channels (inbound captures + outbound replies)
 */

import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

import { generateCode, loadOrCreateChannelId } from "./src/config.js";
import { registerPairingCode } from "./src/supabase.js";
import { mcp, registerToolHandlers, setSendToIos } from "./src/mcp.js";
import { initRealtime, sendToIos, subscribeToCaptures } from "./src/realtime.js";

// ─── Identity ─────────────────────────────────────────────────────────────────

const channelId = loadOrCreateChannelId();
const pairingCode = generateCode();

// ─── Wire up cross-module dependencies ───────────────────────────────────────

// Give the MCP tool handler a way to send messages to iOS
setSendToIos(sendToIos);

// Give Realtime the pairing code for the startup announcement
initRealtime(pairingCode);

// Register tool handlers with the runtime pairing code + channel ID
registerToolHandlers(channelId, pairingCode);

// ─── Boot ─────────────────────────────────────────────────────────────────────

const transport = new StdioServerTransport();
await mcp.connect(transport);

await registerPairingCode(channelId, pairingCode);
subscribeToCaptures(channelId);
