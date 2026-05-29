-- sessions: one row per plugin instance
create table if not exists sessions (
  channel_id      text primary key,
  pairing_code    text,
  code_expires_at timestamptz,
  last_seen       timestamptz not null default now()
);

-- tokens: issued on successful pairing
create table if not exists tokens (
  token       text primary key,
  channel_id  text not null references sessions(channel_id),
  created_at  timestamptz not null default now()
);

-- Row-level security: service role bypasses; anon cannot read
alter table sessions enable row level security;
alter table tokens enable row level security;
