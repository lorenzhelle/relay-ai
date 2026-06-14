import { readFileSync, writeFileSync, existsSync } from "fs";
import { join } from "path";

// ─── Environment ──────────────────────────────────────────────────────────────

export const SUPABASE_URL = process.env.SUPABASE_URL;
export const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error(
    "[relay-agent] SUPABASE_URL and SUPABASE_ANON_KEY must be set.\n" +
      "Copy relay-agent/.env.example → relay-agent/.env and fill in your project values.",
  );
  process.exit(1);
}

// ─── Pairing code ─────────────────────────────────────────────────────────────

/** Characters used in pairing codes — visually unambiguous (no I, O, 0, 1). */
const CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

export const CODE_EXPIRES_MIN = 10;

export function generateCode(): string {
  return Array.from(
    { length: 6 },
    () => CODE_CHARS[Math.floor(Math.random() * CODE_CHARS.length)],
  ).join("");
}

// ─── Persistent channel identity ──────────────────────────────────────────────

const CHANNEL_ID_PATH = join(import.meta.dir, "..", ".channel-id");

/**
 * Returns the channel UUID to use for this agent instance.
 *
 * Resolution order:
 *   1. CHANNEL_ID env var — copy this from the iOS app's Settings screen after
 *      the first launch and add it to relay-agent/.env.
 *   2. .channel-id file — legacy fallback, created automatically on first run.
 */
export function loadOrCreateChannelId(): string {
  if (process.env.CHANNEL_ID) {
    return process.env.CHANNEL_ID.trim();
  }
  if (existsSync(CHANNEL_ID_PATH)) {
    return readFileSync(CHANNEL_ID_PATH, "utf8").trim();
  }
  const id = crypto.randomUUID();
  writeFileSync(CHANNEL_ID_PATH, id, "utf8");
  return id;
}
