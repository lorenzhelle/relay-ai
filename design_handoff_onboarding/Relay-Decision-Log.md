# Relay — Architektur-Entscheidungen (Kurzfassung)

Stand: Mai 2026

## Was ist Relay
Voice-first iOS-Kanal zu einer persönlichen Claude-Code-Instanz, die auf einem Rechner zu Hause 24/7 läuft. **Kein eigenständiges AI-Tool** — ein ruhiger, screenfreier Zugang zu einer Claude-Instanz die bereits Kontext, Tools und autonome Task-Fähigkeit besitzt.

## Transport: Telegram via Claude Code Channels

**Entschieden:** Mai 2026.  Ersetzt ursprünglichen Plan eines eigenen WebSocket-Servers über Tailscale.

Claude Code Channels (ab v2.1.80, research preview) liefern den Transport-Layer fertig:
- Telegram-Plugin (`telegram@claude-plugins-official`) läuft als Bun-Script auf dem Host
- Pairing + Allowlist-Mechanismus eingebaut
- Kein eigener Server, kein Tailscale, kein Auth-Handling

**Konsequenz für die iOS App:** Native App nutzt Telegram als reinen Message-Bus (Bot API direkt). Der Nutzer sieht Telegram nicht — die App ist ein besserer Telegram-Client der genau eine Konversation kennt.

## Client: Native iOS App

`MPRemoteCommandCenter` für AirPods-Stem-Integration, WhisperKit (on-device STT) und Background-Audio-Session sind alle nur nativ möglich. v2-Features (Approval Deck, Custom UI) brauchen sowieso nativen Client.

## Stack

| Layer | Technologie |
|---|---|
| Transport | Telegram Bot API (via Claude Code Channels Plugin) |
| iOS Client | Native Swift App |
| STT | WhisperKit (on-device) |
| TTS | AVSpeech (v1), ElevenLabs (später) |
| AirPods-Integration | MPRemoteCommandCenter |
| Channel-Plugin auf Host | telegram@claude-plugins-official |

## Onboarding-Voraussetzungen

### Auf dem Host (manuell, einmalig)
1. Claude Code installiert + authentifiziert (Pro/Max oder Console API Key)
2. Bun installiert
3. Telegram-Bot via BotFather erstellt → Token
4. Plugin: `/plugin install telegram@claude-plugins-official`
5. Plugin konfigurieren: `/telegram:configure <token>`
6. Claude Code als Background-Service (systemd/launchd)
7. Starten mit `claude --channels plugin:telegram@claude-plugins-official`

### In der iOS App (geführt)
1. Bot-Username oder Token eingeben
2. App schickt erste Message an Bot → Pairing-Code zurück
3. Nutzer gibt Code in Claude Code ein: `/telegram:access pair <code>`
4. App speichert Chat-ID für alle weiteren Messages

## v1 Scope
Voice-only Quick Capture. Nutzer spricht einen Gedanken ein, Claude verarbeitet ihn (z.B. via Obsidian/TickTick MCPs). Keine Bestätigung bei Erfolg (**Silent Dropbox**). Nur bei Fehlern oder expliziter Antwort spricht Claude zurück (`reply_voice`).

Tool-Integrationen leben bei Claude Code über MCPs — **nicht in Relay**. Relay ist ein *Channel*, kein Tool-Wrapper.

## Deferred
- **Think Aloud** — Echtzeit-Sprachunterstützung für Reasoning
- **Morning Approvals** — Batched Review Workflow
- **Async Agent Interface** — breitere asynchrone Task-Ausführung
