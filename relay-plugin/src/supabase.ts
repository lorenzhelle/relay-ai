import { createClient } from "@supabase/supabase-js";
import { SUPABASE_URL, SUPABASE_ANON_KEY, CODE_EXPIRES_MIN } from "./config.js";

// ─── Client ───────────────────────────────────────────────────────────────────

export const supabase = createClient(SUPABASE_URL!, SUPABASE_ANON_KEY!, {
  realtime: { params: { eventsPerSecond: 10 } },
});

// ─── Pairing registration ─────────────────────────────────────────────────────

/**
 * Writes (or refreshes) this plugin's pairing code in Supabase so the
 * `pair` Edge Function can validate it when the iOS app submits a code.
 */
export async function registerPairingCode(
  channelId: string,
  pairingCode: string,
): Promise<void> {
  const expiresAt = new Date(
    Date.now() + CODE_EXPIRES_MIN * 60 * 1000,
  ).toISOString();

  const { error } = await supabase.from("sessions").upsert(
    {
      channel_id: channelId,
      pairing_code: pairingCode,
      code_expires_at: expiresAt,
      last_seen: new Date().toISOString(),
    },
    { onConflict: "channel_id" },
  );

  if (error) {
    console.error(
      "[relay-plugin] failed to register pairing code:",
      error.message,
    );
  } else {
    console.error(
      `[relay-plugin] registered pairing code ${pairingCode} (expires in ${CODE_EXPIRES_MIN}m)`,
    );
  }
}
