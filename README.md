# Relay

A voice-first iOS channel to your personal Claude Code instance. Speak a thought — Relay transcribes it on-device with Whisper, sends it through a private Telegram bot, and Claude Code processes it at home using whichever MCPs you have configured (Obsidian, TickTick, Home Assistant, …). You never open Telegram. The bot is the transport, not the product.

---

## How it works

1. **Speak** — press the Action Button, AirPods stem, or Lock Screen shortcut. Whisper transcribes locally.
2. **Send** — the transcript is sent via your private Telegram bot to the Claude Code Channels plugin running on your home computer.
3. **Done** — Claude routes it: inbox entry, task, reminder, home-automation command. Silent by default; Claude speaks back only on errors or explicit `reply_voice`.

---

## Prerequisites — home computer (one-time, ~5 min)

1. Claude Code installed and authenticated (Pro/Max subscription or API key)
2. Bun installed (`curl -fsSL https://bun.sh/install | bash`)
3. A Telegram bot created via [@BotFather](https://t.me/BotFather) → save the token
4. Install the Channels plugin in Claude Code:
   ```
   /plugin install telegram@claude-plugins-official
   ```
5. Configure with your bot token:
   ```
   /telegram:configure <your-bot-token>
   ```
6. Run Claude Code as a background service with the Channels plugin:
   ```
   claude --channels plugin:telegram@claude-plugins-official
   ```

The iOS app guides you through the pairing step — no further manual setup needed after the above.

---

## Architecture

SwiftUI app, iOS 26.2+. See [`docs/adr/001-mvvm-coordinator-architecture.md`](docs/adr/001-mvvm-coordinator-architecture.md) for the full decision record.

| Layer | Choice |
|---|---|
| UI | SwiftUI, `NavigationStack` |
| Architecture | MVVM + Coordinator |
| STT | WhisperKit (on-device) |
| Transport | Telegram Bot API (direct) |
| Persistence | Keychain for credentials; SwiftData for captures log (upcoming) |
| Default actor isolation | `@MainActor` (project-wide) |

```
relay/
├── App/                  AppCoordinator — root routing
├── Design/               RelayTokens, RelayFonts, shared components
├── Onboarding/           O1–O6 screens + ViewModels
│   ├── Welcome/
│   ├── BotInput/
│   ├── PairingCode/
│   ├── Paired/
│   ├── TriggerPick/
│   └── FirstCapture/
├── Services/             TelegramService, PairingService, KeychainStore
└── Home/                 Post-onboarding (captures log — upcoming)
```

### Architecture rules

These are the load-bearing constraints. Follow them when adding new screens or features.

**1. Services never import SwiftUI.**
`TelegramService`, `PairingService`, `KeychainStore` — pure Foundation. If you find yourself reaching for `@State` or `Color` in a service, move that logic to a ViewModel.

**2. Views never call services directly.**
A View calls a method on its ViewModel. The ViewModel calls the service. The chain is always View → ViewModel → Service, never View → Service.

**3. One ViewModel per screen that has async work. No ViewModel for static screens.**
If a screen is read-only with no user actions (e.g. Welcome, FirstCapture), don't create a ViewModel for it. If it owns async work, a timer, or complex state, it gets one. Don't create ViewModels for consistency's sake.

**4. Navigation lives in the Coordinator, not in Views.**
Views call `coordinator.advance(to:)`. They don't push, present, or navigate themselves. The full onboarding state machine is visible in `OnboardingCoordinator` + `OnboardingStep` — keep it that way.

**5. Credentials go to Keychain, nothing else.**
Bot token and chat-id are secrets. They never touch `UserDefaults`, `AppStorage`, or any file. `KeychainStore` is the only place that reads or writes them.

**6. `@Observable` for ViewModels, `async/await` for Services.**
Don't use `@ObservableObject`/`@Published` — the project is on `@Observable` (Swift 5.9+). Don't use Combine for networking — use `async/await` and structured concurrency (`Task`, `Task.checkCancellation()`).

**7. Store cancellable Tasks on the ViewModel, cancel in `onDisappear`.**
Any polling or long-running `Task` must be stored as a property and cancelled when the view disappears. Pattern: `private var pollingTask: Task<Void, Never>?`, cancelled in `.onDisappear { vm.cancelTasks() }`.

**8. Design tokens only — no hardcoded colors, fonts, or spacing.**
Use `Color.relayInk`, `Font.newsreader(size:)`, `RelaySpacing.cardRadius`, etc. If a value isn't in `RelayTokens` or `RelayFonts`, add it there first.

**9. `AppCoordinator` is the single source of truth for onboarding state.**
It reads Keychain on init. Call `appCoordinator.onboardingComplete()` when pairing finishes — never flip a boolean yourself. Call `appCoordinator.resetToOnboarding()` when credentials are invalidated.

**10. New features go in new top-level folders.**
Captures log → `Home/`. Audio recording → `Audio/`. Settings → `Settings/`. Don't pile new screens into `Onboarding/` or scatter files at the root level.

---

### Custom fonts

The design uses **Newsreader** (serif) and **JetBrains Mono** (monospace). Both are SIL OFL licensed.

1. Download from Google Fonts: [Newsreader](https://fonts.google.com/specimen/Newsreader) · [JetBrains Mono](https://fonts.google.com/specimen/JetBrains+Mono)
2. Place the `.ttf` files in `relay/Resources/Fonts/`:
   - `Newsreader-Regular.ttf`, `Newsreader-Italic.ttf`
   - `JetBrainsMono-Regular.ttf`, `JetBrainsMono-Medium.ttf`
3. The app falls back to New York (serif) and SF Mono if the files are absent.

---

## Development

- Xcode 26.3+
- iOS Simulator: iPhone 16 Pro (iOS 26.2)
- No external Swift packages — all dependencies are system frameworks

```bash
open relay.xcodeproj
# Select "relay" scheme → iPhone 16 Pro simulator → ⌘R
```

---

## Design reference

The `design_handoff_onboarding/` folder contains the full pixel-spec and an interactive HTML prototype. Open `design_handoff_onboarding/Relay\ Prototype.html` in a browser to step through all six onboarding screens.
