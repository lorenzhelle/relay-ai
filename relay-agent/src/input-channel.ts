import type { Server } from "@modelcontextprotocol/sdk/server/index.js";

// ─── Interface ────────────────────────────────────────────────────────────────

export interface CaptureMetadata {
  captureId?: string;
  duration?: string;
  timestamp?: string;
}

/**
 * Abstraction over the mechanism used to inject voice transcripts into Claude.
 * Two implementations exist:
 *   - AgentSdkChannel  (default): feeds transcripts into query() sessions.
 *   - McpNotificationChannel (preserved): sends notifications/claude/channel
 *     over the MCP server. Disabled by default; enable with RELAY_CHANNEL_MODE=mcp.
 */
export interface InputChannel {
  send(transcript: string, meta: CaptureMetadata): void;
}

// ─── Agent SDK Channel ────────────────────────────────────────────────────────

/**
 * Queues voice transcripts and feeds them into the Agent SDK session runner
 * (src/agent.ts). Uses a stored resolve callback that wakes the async generator
 * when a new item arrives — no busy-polling.
 */
export class AgentSdkChannel implements InputChannel {
  private readonly _queue: Array<{ transcript: string; meta: CaptureMetadata }> = [];
  private _resolve: (() => void) | null = null;

  send(transcript: string, meta: CaptureMetadata): void {
    this._queue.push({ transcript, meta });
    this._resolve?.();
    this._resolve = null;
  }

  /**
   * Async generator consumed by runAgentLoop(). Yields queued items as they
   * arrive and parks (without busy-looping) when the queue is empty.
   */
  async *messages(): AsyncGenerator<{ transcript: string; meta: CaptureMetadata }> {
    while (true) {
      while (this._queue.length > 0) {
        yield this._queue.shift()!;
      }
      await new Promise<void>((resolve) => {
        this._resolve = resolve;
      });
    }
  }
}

// ─── MCP Notification Channel (preserved, disabled by default) ───────────────

/**
 * Original channel implementation using notifications/claude/channel.
 * Preserved so it can be re-enabled when Claude Code fixes channel support.
 *
 * Enable by setting:   RELAY_CHANNEL_MODE=mcp
 *
 * Requires the MCP Server instance to be injected via setServer().
 * This is an exact preservation of the forwardCaptureToClaude() and
 * announceToClaudeOnce() logic that previously lived in src/mcp.ts.
 */
export class McpNotificationChannel implements InputChannel {
  private _server: Server | null = null;

  setServer(server: Server): void {
    this._server = server;
  }

  send(transcript: string, meta: CaptureMetadata): void {
    if (!this._server) {
      console.error("[relay-agent] McpNotificationChannel: server not set, dropping transcript");
      return;
    }
    this._server
      .notification({
        method: "notifications/claude/channel",
        params: {
          content: transcript,
          meta: {
            captureId: meta.captureId ?? "",
            duration: meta.duration ?? "",
            timestamp: meta.timestamp ?? new Date().toISOString(),
          },
        },
      })
      .catch(() => {});
  }

  /** One-time startup announcement with the pairing code (MCP mode only). */
  announce(pairingCode: string): void {
    if (!this._server) return;
    this._server
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
}
