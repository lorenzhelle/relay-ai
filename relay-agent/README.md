# relay-agent

An MCP [channel](https://code.claude.com/docs/en/channels.md) that bridges **Claude Code** with the **Relay iOS app**. Record a voice note on your phone — the plugin transcribes it, forwards it to Claude, and speaks the reply back through your phone.

```
iPhone mic  ──► Relay iOS app  ──► Supabase Realtime  ──► relay-agent  ──► Claude
             ◄──  AVSpeech TTS  ◄──  Supabase Realtime  ◄──  reply tool  ◄──
```

> **Research preview**: Claude Code channels require v2.1.80 or later and Anthropic authentication (claude.ai or Console API key). Because this is a custom channel (not on Anthropic's approved allowlist), you must pass `--dangerously-load-development-channels` when starting Claude Code — see [Start a session](#3-start-a-session-with-the-channel-enabled) below.

## Requirements

| Tool | Version |
|------|---------|
| [Bun](https://bun.sh) | ≥ 1.0 |
| Claude Code | ≥ v2.1.80 |
| Supabase project | with Realtime enabled |

## Setup

### 1. Install dependencies

```bash
cd relay-agent
bun install
```

### 2. Configure environment

```bash
cp .env.example .env
```

Edit `.env` and fill in your Supabase project URL and anon key (found under **Settings → API** in the Supabase dashboard):

```dotenv
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### 3. Register with Claude Code

Add the plugin to your project-level `.mcp.json` (or under `mcpServers` in `~/.claude.json` for user-level config):

```json
{
  "mcpServers": {
    "relay": {
      "command": "bun",
      "args": ["run", "/absolute/path/to/relay-agent/index.ts"]
    }
  }
}
```

The env vars are read from `.env` automatically — no need to duplicate them in the MCP config.

### 4. Start a session with the channel enabled

Because this is a custom channel not yet on Anthropic's allowlist, start Claude Code with the development bypass flag and reference the server by name:

```bash
claude --dangerously-load-development-channels server:relay
```

Claude Code reads `.mcp.json`, spawns the plugin as a subprocess over stdio, and activates it as a channel. You'll see it announce the pairing code in your session.

### 5. Pair your iPhone

The plugin prints a 6-character pairing code at startup. In the Relay iOS app tap **Connect** and enter the code. The code expires after 10 minutes; restart the session to get a fresh one.

You can also ask Claude: *"what's my pairing code?"* — it will call `get_pairing_info` and show the current code.

## How it works

Claude Code channels work over MCP using `notifications/claude/channel` events. This plugin:

1. Declares the `claude/channel` capability so Claude Code registers a notification listener
2. Connects over stdio (Claude Code spawns it as a subprocess)
3. Subscribes to Supabase Realtime to receive voice captures from the iOS app
4. Forwards each transcript to Claude as a `<channel source="relay" ...>` event
5. Exposes a `reply` tool so Claude can speak responses back through the app

## Project structure

```
relay-agent/
├── index.ts          # Boot: wires modules together and starts the server
├── src/
│   ├── config.ts     # Env vars, pairing-code generation, channel-ID persistence
│   ├── supabase.ts   # Supabase client + pairing-code registration
│   ├── mcp.ts        # MCP server, tool definitions, Claude channel helpers
│   └── realtime.ts   # Supabase Realtime subscriptions (inbound/outbound)
├── .env.example      # Environment template
├── .channel-id       # Auto-generated UUID (gitignored) — persists the channel across restarts
└── package.json
```

> **Development note**: You can't run this plugin standalone with `bun run index.ts` and have it do anything useful — it communicates with Claude Code over stdio and must be spawned by Claude Code. Use `--dangerously-load-development-channels server:relay` to run it in a real session, or `bun --watch run index.ts` as a syntax/import check only.

## Message protocol

All iOS↔plugin messages are Supabase Realtime **broadcast** events on the `message` event.

### iOS → Plugin (`relay:{channelId}:ios-to-plugin`)

| Field | Type | Description |
|-------|------|-------------|
| `type` | `"capture"` | Voice note transcript |
| `transcript` | `string` | Transcribed text |
| `clientCaptureId` | `string` | Client-generated ID for deduplication |
| `durationSeconds` | `number?` | Recording duration |
| `timestamp` | `string?` | ISO-8601 capture time |

### Plugin → iOS (`relay:{channelId}:plugin-to-ios`)

| `type` | Payload | Description |
|--------|---------|-------------|
| `ack` | `{ clientCaptureId }` | Confirms capture received |
| `speak` | `{ text }` | Text for AVSpeech to read aloud |

### Plugin → Claude Code (MCP channel events)

Voice transcripts are forwarded as `notifications/claude/channel` with:

| Field | Value |
|-------|-------|
| `content` | The transcribed text |
| `meta.captureId` | `clientCaptureId` from the iOS payload |
| `meta.duration` | Recording duration in seconds (string) |
| `meta.timestamp` | ISO-8601 capture time |

Claude sees these as: `<channel source="relay" captureId="..." duration="..." timestamp="...">transcript</channel>`

## MCP tools

| Tool | Description |
|------|-------------|
| `reply` | Send a text reply to the iOS app (spoken via AVSpeech) |
| `get_pairing_info` | Return the current pairing code, channel ID, and setup instructions |

## Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | ✅ | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | ✅ | Your Supabase anon (public) key |
