-- Allow the plugin (using the anon key) to register and refresh its own session.
-- sessions only holds routing metadata (channel_id, pairing_code, expiry) — no secrets.
create policy "anon can upsert sessions"
  on sessions for all
  to anon
  using (true)
  with check (true);

-- tokens are issued by the pair Edge Function (service role); anon cannot read or write them.
-- No policy needed — RLS with no permissive policy defaults to deny.
