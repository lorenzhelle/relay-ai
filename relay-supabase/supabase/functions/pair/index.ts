import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import type { PairRequest, PairResponse } from "../../../types.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  let body: PairRequest;
  try {
    body = await req.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  const code = body.code?.trim().toUpperCase();
  if (!code || code.length !== 6) {
    return json({ error: "code_required" }, 400);
  }

  // Look up the session by pairing code (must not be expired)
  const { data: session, error } = await supabase
    .from("sessions")
    .select("channel_id")
    .eq("pairing_code", code)
    .gt("code_expires_at", new Date().toISOString())
    .single();

  if (error || !session) {
    return json({ error: "invalid_or_expired_code" }, 404);
  }

  // Issue a token stored in the tokens table
  const token = crypto.randomUUID();
  await supabase.from("tokens").insert({
    token,
    channel_id: session.channel_id,
    created_at: new Date().toISOString(),
  });

  const res: PairResponse = { channelId: session.channel_id, token };
  return json(res, 200);
});

function json(data: unknown, status: number): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
