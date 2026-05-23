# Handoff: Relay Onboarding (iOS)

## Overview
The first-run flow for **Relay** — a voice-first iOS client that pairs to a private Telegram bot which forwards messages to a Claude Code instance running on the user's home computer (Claude Code Channels plugin: `telegram@claude-plugins-official`).

The user never opens Telegram. The bot is just the transport. From the user's perspective, they install the app, pair it once to their bot, pick a trigger (Action Button / AirPods / Shortcut), and start dictating.

Six screens, in order:
1. **O1 Welcome** — explains what Relay is + lists what must be set up on the home computer beforehand
2. **O2 Bot eingeben** — user types their bot username (`@mein_relay_bot`)
3. **O3 Pairing-Code** — app sends `/start` to the bot, displays the pairing code the home computer returned, instructs the user to paste `/telegram:access pair <code>` into their Claude Code session
4. **O4 Paired** — success state, shows connection metadata + downloads on-device Whisper model
5. **O5 Pick a trigger** — chooses how the user opens Relay (Action Button highlighted as default)
6. **O6 First capture** — landing screen with three usage tips and a "try it" button

## About the design files
The files in this bundle are **design references created in HTML/React** — prototypes showing intended look and behavior, not production code to copy directly.

The task is to **recreate these designs as a native iOS app in SwiftUI** (or UIKit). The aesthetic and copy are final, but the implementation is yours — use SwiftUI's idioms (`NavigationStack`, `TextField`, `.sheet`, system haptics, etc.).

## Fidelity
**Hi-fi.** Colors, typography, copy, spacing, and the overall feel are final. Implement pixel-close. The only intentional flex is icons — current SVG glyphs are placeholders; substitute SF Symbols where appropriate (e.g. `mic.fill`, `airpods`, `checkmark`, `iphone.gen3`).

## Design tokens

### Colors
| Token | Value | Use |
|---|---|---|
| `bg` | `#F2EEE4` | warm cream — main background |
| `paper` | `#FAF6EC` | inset cards (settings sections, code blocks) |
| `ink` | `#181613` | primary text + primary CTA |
| `muted` | `rgba(24,22,19,0.58)` | secondary text |
| `faint` | `rgba(24,22,19,0.34)` | tertiary / metadata |
| `hair` | `rgba(24,22,19,0.09)` | hairline separators |
| `hair2` | `rgba(24,22,19,0.16)` | stronger hairlines / borders |
| `sage` | `oklch(0.58 0.055 165)` ≈ `#6D8C7A` | success / connected |
| `amber` | `oklch(0.66 0.14 55)` ≈ `#C8823A` | recording / pairing-pending |
| `rust` | `oklch(0.55 0.14 28)` ≈ `#B45A3C` | destructive / error |
| `dark text on ink` | `#F8F4EA` | text on dark surfaces |

### Typography
| Role | Family | iOS substitute |
|---|---|---|
| Display / body prose | **Newsreader** (Google Fonts, opsz 6–72) | Embed Newsreader, or fall back to **New York** (`UIFontDescriptor.SystemDesign.serif`) |
| UI / buttons | "Söhne" → fall back to **SF Pro Text** | `.system(.body, design: .default)` |
| Mono / metadata / CLI | **JetBrains Mono** | Embed JetBrains Mono, or fall back to **SF Mono** (`.system(.body, design: .monospaced)`) |

Newsreader's italic is used heavily for muted-secondary sentences — keep this. The visual rhythm is: bold serif headline → muted italic serif subtitle → mono metadata. Don't substitute a sans for the headline.

### Type scale (approx)
| Use | Size | Weight | Line height | Tracking |
|---|---|---|---|---|
| Display (welcome headline) | 40pt | regular | 1.1 | −0.7 |
| Screen title | 28pt | regular | 1.2 | −0.4 |
| Success heading (Verbunden.) | 36pt | regular | 1.05 | −0.6 |
| Body serif | 17pt | regular | 1.5 | −0.1 |
| Body small serif | 14–15pt | regular | 1.45 | −0.05 |
| UI label | 15pt | medium | — | −0.1 |
| Button | 16pt | medium | — | −0.1 |
| Mono | 10–12pt | regular/medium | 1.4 | +0.2 to +1.2 (uppercase labels) |

Uppercase mono labels (`vorausgesetzt`, `aliases`, etc.) use letter-spacing 1.2px and color `faint`.

### Spacing
- Screen horizontal padding: 24–28pt
- Header padding: 60pt top, 18pt bottom
- Bottom CTA inset: 34pt from bottom
- Card padding: 14–18pt
- Card radius: 12–18pt
- Button radius: 16–18pt
- Hairline: 0.5px solid

### Buttons
- **Primary (solid)**: full-width, height 60pt, radius 18pt, background `ink`, text `#F8F4EA`, 16pt medium
- **Secondary (ghost)**: same size, transparent, 1pt border in `hair2`, text `ink`
- **Step indicator**: row of 6pt dots, gap 6pt. Past + current = `ink` (current is 18pt wide pill). Future = `hair2`. Animate transitions 0.3s.

### Status header (`RelayHeader`)
A custom header replaces the system nav. Layout: 60pt top padding, 24pt horizontal, 18pt bottom.
- Left: status dot (8pt, color depends on status) + "relay" word in 19pt medium sans
- Right: mono detail string, 10.5pt, `muted`, lowercase
- Status colors: `connected` → sage, `recording` → amber (with halo `amber@22% × 4pt`), `offline` → rust, `speaking` → amber

---

## Screen-by-screen spec

For each screen below: 402×874 frame (iPhone 16 Pro logical), background `bg`.

### O1 — Welcome
**Header**: status `offline`, detail "not paired"

**Body (top, padding 64pt × 28pt)**:
- Display headline, Newsreader 40pt, 2 lines:
  - Line 1: "Ein ruhiger Kanal" (ink)
  - Line 2: "zu dem, was zu Hause auf dich wartet." (italic, color `faint`)
- 24pt gap → body serif 17pt muted: *"Relay ist ein Mikrofon. Was du sagst, geht über einen privaten Telegram-Bot an deine Claude-Code-Instanz zu Hause — Telegram siehst du nie, der Bot ist nur die Leitung."*

**Prerequisites card (32pt below)**:
- Dashed border in `hair2`, radius 14, padding 16×18
- Header row: uppercase mono `auf dem rechner · einmalig` (left) + `~5 min` (right faint)
- 4 numbered steps (mono `1`–`4` in faint, body serif 14pt ink):
  1. Claude Code & Bun installiert
  2. Telegram-Bot via BotFather → Token
  3. `/plugin install telegram@claude-plugins-official` (mono inline)
  4. Mit `--channels` als Service laufen lassen
- Hairline separator, then mono 10pt faint: *"Anleitung steht in der README · kein Tailscale, kein eigener Server"*

**Bottom**:
- Step dots (1 of 5)
- Primary CTA: "Rechner ist bereit"
- Secondary mono line: "sonst erst dort einrichten"

**Navigation**: tap primary → O2

---

### O2 — Bot eingeben
**Header**: status `offline`, detail "bot · setup"

**Body**:
- Title (serif 28): "Dein Bot ist die Leitung."
- Subtitle (serif italic 14.5 muted): "Gib den Username deines Telegram-Bots ein — den, den du via BotFather erstellt und auf deinem Rechner konfiguriert hast."
- Field group:
  - Uppercase mono label "bot username"
  - Input (radius 12, paper bg, 1pt ink border = focused state): leading "@" in faint, then bot name in ink mono 16pt + blinking caret (steps(2), 0.9s, infinite)
  - Mono 10pt hint: "findest du in BotFather · Format @name oder t.me/name"
- Recap card (paper bg, hair2 border, radius 12, padding 14×16):
  - Header: "auf dem rechner, vorher" + "✓ erledigt?"
  - 3 mono lines (12pt ink), prefixed with faint `$`:
    - `/plugin install telegram@claude-plugins-official`
    - `/telegram:configure <token>`
    - `claude --channels plugin:telegram@…`
- Inline link row (mono 10.5 faint): "token lieber direkt eintippen? **Token statt Username**" (last words underlined, ink color)

**Bottom**:
- Step dots (2 of 5)
- Primary CTA: "Nachricht schicken"
- Secondary: "Relay schickt /start an den Bot und wartet auf den Pairing-Code"

**Behavior**:
- Validate that input matches `@?[a-zA-Z0-9_]+_bot` or a full `t.me/...` URL or a bot token (`\d+:[\w-]+`)
- On tap: post `/start` to the bot using Telegram Bot API → wait for the home computer to respond with a pairing code → navigate to O3

---

### O3 — Pairing-Code
**Header**: status `offline`, detail "warte auf claude code"

**Body**:
- Title (serif 28): "Sag deiner Claude, dass das du bist."
- Subtitle (italic): "Relay hat eine Nachricht an deinen Bot geschickt. Dein Rechner hat geantwortet — mit diesem Code:"
- **Code card** (paper bg, hair2 border, radius 16, padding 22×18, text-align center):
  - Uppercase mono label: "pairing code · 90 s gültig"
  - Big mono 22pt letter-spacing 2: `OAK · RIVER · 7142`
- **Command card** (ink bg, `#F8F4EA` text, radius 12):
  - Header: "tipp das in claude code" + "copy" (right, ink-colored interactive)
  - Mono 12.5pt content: prompt `>` then `/telegram:access pair` then indented `oak-river-7142`
- **Waiting indicator** (dashed border, padding 14×16):
  - Amber pulsing dot (halo `amber@22% × 5pt`)
  - Serif 14: "Warte auf Bestätigung vom Rechner…"
  - Mono 10: "schliesst von selbst, sobald der Code erkannt ist"

**Bottom**:
- Step dots (3 of 5)
- Primary CTA (ghost): "neuen Code anfragen"
- Secondary: "Rechner nicht erreichbar? Bot-Username prüfen"

**Behavior**:
- Poll Telegram (long-poll `getUpdates` or webhook proxy) for the home computer's confirmation reply
- On success → navigate to O4
- 90s timeout → reset code, re-enable primary CTA to re-request
- Copy button copies `/telegram:access pair oak-river-7142` to pasteboard with haptic confirmation

---

### O4 — Paired
**Header**: status `connected`, detail "verbunden"

**Body**:
- Success ring (56pt circle, 1.25px sage border, contains 20pt sage checkmark)
- 22pt below → headline serif 36pt: "Verbunden."
- 10pt below → italic serif 17pt muted: "Dein Bot ist gepaart, Claude Code hört zu. Erster Round-trip war 412 ms — Telegram ist halt nicht der schnellste, aber stabil."
- 32pt below → hairline → key/value rows (mono 11.5):
  - `bot` / `@mein_relay_bot`
  - `chat-id` / `8 421 9·· ····`
  - `channel` / `telegram@claude-plugins-official`
  - `claude code` / `up · 4d 11h`
  - `mcps` / `4 · obsidian · ticktick · home · gmail`
- 26pt below → Whisper download progress:
  - Header row mono 11: "whisper base · multilingual" / "97 / 152 MB"
  - 3pt track in `hair`, 64% filled sage

**Bottom**:
- Step dots (4 of 5)
- Primary CTA: "weiter"

**Behavior**: download Whisper Base multilingual model in background. Allow advancing even before download completes — show progress on Home if still downloading.

---

### O5 — Pick a trigger
**Header**: status `connected`, detail "last step"

**Body**:
- Title serif 30: "Wie öffnest du Relay?"
- Subtitle italic 15 muted: "Wähl einen Trigger. Die anderen kannst du später auch noch dazu legen."
- iPhone silhouette diagram (120×100 SVG) showing edge view with **Action Button** highlighted in amber + label line + "action" text
- Three options (stacked, gap 10pt):
  - Selected style: 1.5pt ink border, paper bg, icon in 36pt ink square with cream icon, ink checkmark on right
  - Unselected: 0.5pt hair2 border, transparent, icon in 36pt outlined square
  - Each: bold sans label + mono hint underneath
  - 1. **Action Button** — "ein Druck · öffnet & nimmt auf" (default selected)
  - 2. **AirPods · Stem long-press** — "im Hosentaschen-Modus, hands-free"
  - 3. **Lock-Screen Shortcut** — "aus der unteren rechten Ecke"

**Bottom**:
- Step dots (5 of 5)
- Primary CTA: "Shortcut installieren"
- Secondary: "oder später · Settings → Trigger"

**Behavior**:
- Action Button: deep link the user into Settings → Action Button via `App-Prefs:` or the iOS 18 `IntentDonation` API
- AirPods: register `MPRemoteCommandCenter` handlers (the actual integration; see decision log)
- Lock-Screen Shortcut: install an `App Shortcut` and link to Shortcuts to add to Lock Screen

---

### O6 — First capture (landing)
**Header**: status `connected`, detail "paired · ready"

**Body**:
- Headline serif 34: "Ein ruhiger Kanal *zu dem, was zu Hause auf dich wartet.*"
- 36pt below → 3 numbered tips (22pt outlined circles, body serif 17pt):
  1. "Halt das Telefon ans Ohr oder drück den AirPods-Stem."
  2. "Sprich frei. Pausen sind okay. Multi-Item ist okay."
  3. "Loslassen. Claude legt es da ab, wo es hingehört."
- 40pt below → dashed-border card: "verbunden via" / mono "@mein_relay_bot → claude code" / mono small "4 mcps available · obsidian, ticktick, home-assistant, gmail"

**Bottom CTA**: Full-width "Hold to speak" ink button (same as Home), label "try it", sub "say anything · captured silently"

**Behavior**: this is the first real Home screen. After first capture, swap "try it" copy back to "hold to speak" and start filling the captures log.

---

## Interactions & state

### State machine
```
Welcome ──tap────▶ BotInput
BotInput ──valid──▶ sending /start ──ok──▶ PairingCode
                                    └fail▶ BotInput + error toast
PairingCode ──polled confirmation──▶ Paired
            └timeout (90s)──▶ PairingCode (refresh)
Paired ──tap weiter──▶ TriggerPick
TriggerPick ──tap────▶ FirstCapture (Home)
```

### Persistence
Once paired, store in Keychain:
- Bot token (or username + chat-id, depending on flow)
- Chat-id (the user's allowed chat)
- Channel plugin name (informational)

The pairing handshake never has to run again. If the token is invalidated server-side, fail open back into BotInput with a "re-pair" prompt.

### Haptics
- Pairing success (O3 → O4 transition): `.success` notification feedback
- Trigger selection (O5): `.light` impact on tap
- Copy command (O3): `.medium` impact

### Animations
- Step dots: transitions in 0.3s spring
- O3 → O4: success ring fades in + checkmark draws in over 0.5s, then content slides up 12pt fading in over 0.3s
- Pulsing amber dots: 1.2s ease-in-out, scale 1 → 1.15, opacity 1 → 0.6, infinite alternate
- Caret blink: 0.9s steps(2), infinite

---

## Assets to source / build
- **Newsreader** font: Google Fonts → SIL OFL — bundle as `.otf` in app
- **JetBrains Mono** font: Google Fonts → SIL OFL — bundle as `.otf`
- All glyph icons are SVG placeholders in the prototype — replace with SF Symbols:
  - Mic glyph → `mic.fill`
  - Checkmark → `checkmark`
  - Action Button glyph → custom (small vertical rect — keep)
  - AirPods → `airpods.gen3`
  - Lock screen → `lock`
  - Phone silhouette in O5 → custom illustration (can lift the SVG from `screens.jsx`)

---

## Files in this bundle
- `README.md` — this document.
- `Relay-Decision-Log.md` — short version of the architecture decisions behind the design (Telegram-bot transport, not Tailscale).
- `screenshots/` — one PNG per onboarding screen (`01-O1-welcome.png` through `06-O6-first-capture.png`), 402×874 design dimensions. Use as visual reference / changelog thumbnails; for pixel-perfect work open the HTML.
- `Relay Prototype.html` — interactive prototype. Open in a browser to step through all screens.
- `screens.jsx` — full React source. Onboarding screens are `ScreenOnboardWelcome`, `ScreenOnboardPairQR` (now bot-input), `ScreenOnboardPairManual` (now pairing-code), `ScreenOnboardPaired`, `ScreenOnboardTrigger`, `ScreenFirstRun`. Pull exact values from there.
- `ios-frame.jsx`, `design-canvas.jsx` — supporting components used only for the design canvas presentation. Not relevant to the app build.

## Notes for the developer
- **The bot is invisible to the user.** Don't surface Telegram branding anywhere — no Telegram icon, no "powered by Telegram." It's the transport, not the product.
- **Silent dropbox.** v1 has no spoken confirmation on success — see the main screens for the ack pattern. Only `reply_voice` from Claude triggers TTS playback.
- **Pairing is a one-way authorization gate** from the home computer's perspective. The user's chat-id is added to the allowlist via `/telegram:access pair`. Don't store anything sensitive about the home computer in the app.
