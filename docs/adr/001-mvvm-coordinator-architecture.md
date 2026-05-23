# ADR 001 — MVVM + Coordinator as the iOS architecture

**Status:** Accepted  
**Date:** 2026-05-23  
**Author:** Lorenz Helle

---

## Context

Relay is a voice-first iOS app. Its first user-facing surface is a 6-screen onboarding flow with a well-defined state machine:

```
Welcome → BotInput → PairingCode → Paired → TriggerPick → FirstCapture
```

The flow involves three distinct async operations:

1. Send `/start` to a Telegram bot via the Bot API and receive a pairing code
2. Poll for confirmation from the home computer (90-second timeout, retry)
3. Download the Whisper Base multilingual model in the background (~152 MB)

The project targets iOS 26.2 and uses SwiftUI exclusively. Three architectures were evaluated.

---

## Options considered

### MVC

Traditional UIKit pattern. In SwiftUI there is no `UIViewController` — the `View` struct already handles both the template and event routing. Applying MVC to SwiftUI either produces fat Views (controller logic bleeds in) or produces a "Controller" class that is MVVM under a different name. Rejected.

### TCA (The Composable Architecture)

Principled state-machine architecture that maps well onto this flow. Rejected for now because: (a) it adds a third-party dependency, (b) the reducer boilerplate is disproportionate for a solo project at this stage, and (c) the onboarding state machine is simple enough that a plain Coordinator covers it without TCA's overhead. Revisit if the app grows toward approval decks or complex async agent state.

### MVVM + Coordinator

- Each screen that owns async logic gets a paired `@Observable` ViewModel.
- Static screens (Welcome, FirstCapture) have no ViewModel.
- A `Coordinator` class owns a `NavigationStack<OnboardingStep>` path, keeping the state machine explicit and unit-testable without touching SwiftUI.
- Services are isolated `async` classes, consumed by ViewModels via `await`.

**Selected.**

---

## Decision

Use **MVVM + Coordinator** with the following specifics:

| Layer | Technology | Notes |
|---|---|---|
| State observation | `@Observable` (Swift 5.9 / iOS 17+) | No `@Published` noise; composition via `@Environment` |
| Navigation | `NavigationStack<OnboardingStep>` | Enum-typed path, fully reversible, testable without UI |
| Coordinators | `@Observable` classes | `AppCoordinator` at root; `OnboardingCoordinator` for the flow |
| Services | Plain `class` with `async` methods | `@MainActor` by project default; URLSession suspends, doesn't block |
| Persistence | `KeychainStore` wrapping `SecItem` APIs | Secrets (bot token, chat-id) never go to UserDefaults |
| Default actor isolation | `@MainActor` (project-wide build setting) | All `@Observable` types are MainActor; explicit `nonisolated` where needed |

---

## Consequences

- Every screen pair is View + ViewModel. Screens with no business logic (Welcome, FirstCapture) have no ViewModel — don't create one just for consistency.
- The `AppCoordinator` is the single source of truth for whether the user has completed onboarding. It reads the Keychain on launch; if credentials are present, onboarding is skipped entirely.
- Services return typed `Result`/`throws` — ViewModels own error presentation, services own network logic.
- SwiftData (from the initial Xcode template) is removed for now. It will be reintroduced when the captures log screen is built.
