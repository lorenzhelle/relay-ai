import { readFileSync, writeFileSync, existsSync } from "fs";
import { join } from "path";

// ─── Environment ──────────────────────────────────────────────────────────────

export const SUPABASE_URL = process.env.SUPABASE_URL;
export const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error(
    "[relay-plugin] SUPABASE_URL and SUPABASE_ANON_KEY must be set.\n" +
      "Copy relay-plugin/.env.example → relay-plugin/.env and fill in your project values.",
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
 * Returns the persisted channel UUID, creating one on first run.
 * The channel ID is stable across restarts so the iOS app can reconnect
 * without re-pairing.
 */
export function loadOrCreateChannelId(): string {
  if (existsSync(CHANNEL_ID_PATH)) {
    return readFileSync(CHANNEL_ID_PATH, "utf8").trim();
  }
  const id = crypto.randomUUID();
  writeFileSync(CHANNEL_ID_PATH, id, "utf8");
  return id;
}
