# relay-supabase

Supabase configuration, shared protocol types, and Edge Functions for the Relay monorepo.

## What lives here

| Path | Purpose |
|---|---|
| `types.ts` | Shared TypeScript types for the Supabase Broadcast protocol |
| `supabase/config.toml` | Supabase CLI local dev config |
| `supabase/functions/pair/` | Edge Function: validates iOS pairing code → returns channelId + token |
| `supabase/migrations/` | SQL migrations for sessions + tokens tables |
| `.env.example` | Copy to `.env` and fill in your project keys |

## Supabase Realtime channel topology

```
iOS app
  → publishes CaptureEvent
  → channel: relay:{channelId}:ios-to-plugin

relay-plugin (Claude Code MCP plugin)
  → subscribes to ios-to-plugin channel
  → publishes AckEvent / SpeakEvent
  → channel: relay:{channelId}:plugin-to-ios

iOS app
  → subscribes to plugin-to-ios channel
  → plays spoken reply / shows ack
```

All messages are **ephemeral Broadcast** — they live in Supabase RAM for milliseconds and are never written to Postgres. There is no message history.

## Local dev setup

```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Copy env
cp .env.example .env
# → fill in your Supabase project URL and keys

# Start local Supabase (Docker required)
cd relay-supabase
supabase start

# Serve Edge Function locally
supabase functions serve pair --env-file .env

# Deploy to production
supabase functions deploy pair --project-ref <your-project-ref>
```

## Migrations

```bash
# Apply to local dev DB
supabase db reset

# Push to production
supabase db push --project-ref <your-project-ref>
```

## Security notes

- The `pair` Edge Function uses the **service role key** — never expose it on the client.
- iOS and relay-plugin use the **anon key** only for Realtime Broadcast subscriptions.
- AES-GCM end-to-end encryption of Broadcast payloads is **deferred to Phase 2**. For v1, trust is established by the pairing code flow and ephemeral channel names.

## Free tier limits

| Resource | Limit | Expected usage |
|---|---|---|
| Realtime connections | 500 | 2 (iOS + plugin) |
| Realtime events/month | 2,000,000 | ~1,500 min/month × ~2 events ≈ 3,000 |
| Edge Function invocations | 500,000 | ~5 pairings/month |
