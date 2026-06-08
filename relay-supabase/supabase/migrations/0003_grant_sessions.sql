-- Grant table-level privileges so the anon role can exercise the RLS policy.
-- RLS policies alone are not enough — Postgres requires GRANT too.
grant select, insert, update on public.sessions to anon;
