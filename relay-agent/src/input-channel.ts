export interface CaptureMetadata {
  captureId?: string;
  duration?: string;
  timestamp?: string;
  /** When false, the agent should not call reply — work silently. Defaults to true. */
  voiceReply?: boolean;
}

export interface InputChannel {
  send(transcript: string, meta: CaptureMetadata): void;
}

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
