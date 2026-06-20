# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

**Relay** is a voice-first assistant that lets you speak a thought on iPhone, have it transcribed on-device by WhisperKit, forwarded to a home computer running a Claude agent loop, processed with full MCP tool access, and replied to silently or via TTS — all over Supabase Realtime.

Three packages:
- **relay-ios** — SwiftUI iOS app (Xcode)
- **relay-agent** — TypeScript/Bun MCP-connected agent loop
- **relay-supabase** — Supabase backend schema, Edge Functions, shared protocol types

## Development Commands

### iOS (relay-ios)
Requires Xcode 26.3+, targeting iPhone 16 Pro simulator, iOS 26.2 minimum.
```bash
# Build
xcodebuild -scheme relay -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Run tests
xcodebuild test -scheme relay -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Run a single test class
xcodebuild test -scheme relay -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:relayTests/ClassName
```

### Agent (relay-agent)
Runtime: Bun (not Node — must use `bun` directly).
```bash
cd relay-agent
bun install
bun run dev        # watch mode (development)
bun run start      # production
bun run local      # local test mode: stdin/stdout, no Supabase needed
```

### Supabase backend (relay-supabase)
```bash
cd relay-supabase
supabase start                          # start local Supabase stack
supabase functions serve pair           # serve Edge Function locally
supabase db push                        # apply migrations
supabase deploy                         # deploy to cloud
```

## Architecture

### iOS: MVVM + Coordinator

**AppCoordinator** (`App/AppCoordinator.swift`) is the single source of truth. It checks Keychain on launch and routes to onboarding or home. It owns the `AVSpeechSynthesizer` for TTS and handles all incoming Supabase Realtime events (`ack`, `speak`, `text`).

**OnboardingCoordinator** runs a state machine: `Welcome → BotInput → PairingCode → Paired → TriggerPick → FirstCapture`. Navigates a `NavigationStack<OnboardingStep>`.

**CaptureViewModel** (`Capture/CaptureViewModel.swift`) orchestrates the recording flow via a state enum: `idle → listening → recording → transcribing → captured`. It owns `AudioRecorder`, `SpeechTranscriptionService`, and `CaptureStore`.

**RelayCaptureService** (`Services/RelayCaptureService.swift`) speaks the Phoenix WebSocket protocol directly (no Supabase iOS SDK) over `URLSessionWebSocketTask`. It subscribes to `relay:{channelId}:plugin-to-ios` and publishes on `relay:{channelId}:ios-to-plugin`.

**KeychainStore** (`Services/KeychainStore.swift`) wraps `SecItem` APIs — only the `channelId` is persisted here; nothing goes in `UserDefaults`.

### Agent: TypeScript/Bun

**index.ts** — entry point: loads/creates channelId, generates pairing code, subscribes to Supabase, starts agent loop.

**agent.ts** — wraps `@anthropic-ai/claude-agent-sdk` `query()`. Reads transcripts from `AgentSdkChannel`, selects system prompt based on `voiceReply` mode (short/conversational vs. detailed), extracts last assistant text, forwards to iOS.

**realtime.ts** — Supabase Realtime integration. `subscribeToCaptures()` listens for `capture` broadcast events; `routeCapture()` validates payload, enqueues to `inputChannel`, sends ack. `sendToIos()` broadcasts ack/speak/text events.

**input-channel.ts** — `AgentSdkChannel` decouples Supabase events from the SDK session via an async generator with a single pending-resolve pattern (no busy-poll).

### Backend: Supabase

All messages are **ephemeral broadcast** (no persistence, no history).

**Edge Function `/pair`** validates a 6-char pairing code against the `sessions` table, issues a token, returns `{ channelId, token }`. Uses service role key — never expose on the client.

**Database**: `sessions` (one per agent instance: `channel_id`, `pairing_code`, `code_expires_at`) and `tokens` (one per iOS device pairing).

**Shared types** in `relay-supabase/types.ts`: `CaptureEvent`, `AckEvent`, `SpeakEvent`, `PairRequest`, `PairResponse`.

## Architecture Rules (from README)

These are hard rules enforced across the codebase:

1. Services don't import SwiftUI — they are plain Swift classes with `async` methods
2. Views call ViewModels, not Services directly
3. One ViewModel per screen that has async work
4. Navigation lives in Coordinators, not Views
5. Credentials go to Keychain only — never `UserDefaults` or `AppStorage`
6. `@Observable` + `async/await` — no Combine, no `@Published`
7. Cancel polling tasks in `onDisappear`, not `deinit`
8. Use only design tokens (`RelayTokens`, `RelayFonts`, `RelaySpacing`) — no hardcoded colors/fonts
9. `AppCoordinator` is the single source of truth for app-wide state
10. New features get their own folder (`FeatureName/FeatureNameView.swift`, etc.)

## Environment Setup

**relay-agent/.env** (required):
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
CHANNEL_ID=optional-uuid   # persisted to .channel-id file if omitted
```

**relay-supabase/.env** (required for CLI):
```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...  # for Edge Functions only
```

To use relay-agent as an MCP server in Claude Code, it must be registered in `.mcp.json` and Claude Code started with `--dangerously-load-development-channels`.

## Key Design Decisions

- **Transcription is fully on-device** via Apple's iOS 26 `Speech` framework (`SpeechAnalyzer` + `SpeechTranscriber`) — no audio ever leaves the iPhone, no third-party dependencies
- **Supabase Realtime Broadcast** is used for its low latency and ephemeral semantics; Postgres Realtime is not used
- **Phoenix WebSocket protocol** is spoken directly on iOS (no Supabase iOS SDK dependency)
- **Bun** is the runtime for relay-agent — not Node, not ts-node
- **`@MainActor` isolation** is the default for the entire iOS project (set at build level)
- **Pairing codes** expire after 10 minutes and use an unambiguous 6-char alphabet (no I, O, 0, 1)
