# Sonarus Release Verification Checklist

_Last updated: April 19, 2026_

This checklist is the repo-local QA gate for the current Sonarus architecture:
- a **SwiftUI host app** owns permissions, audio capture, transcription orchestration, model management, and history review;
- a future **keyboard extension** should rely on shared App Group state and transcript handoff rather than live microphone capture; and
- shared storage/services live in `SonarusCore`.

## Automated baseline

- [ ] `swift test` passes for `SonarusCore` storage, keyboard bridge, model-management, permissions, and transcription stubs
- [ ] `xcodegen generate` succeeds
- [ ] `xcodebuild ... build-for-testing` succeeds for the `Sonarus` scheme
- [ ] Added or changed behavior includes focused tests in `Tests/SonarusCoreTests` and/or `SonarusTests`
- [ ] No repo guidance files were missed (`CLAUDE.md` / `AGENTS.md` were absent when this checklist was added)

## Permissions and onboarding

- [ ] First-launch SwiftUI routing lands on the expected screen for setup vs returning-user states
- [ ] Microphone and speech-permission states render a recoverable UX
- [ ] Previously denied permissions can be recovered through Settings without reinstalling the app
- [ ] Permission-denied state does not leave the app or future keyboard surfaces in a dead end

## Offline / on-device behavior

- [ ] Once a model is installed, dictation flows work without network access
- [ ] First-time model acquisition fails gracefully when offline
- [ ] No hidden cloud dependency appears during an offline smoke pass
- [ ] Offline state messaging is clear in the app shell and any keyboard-facing handoff UI

## History correctness

- [ ] Successful transcripts save exactly once
- [ ] Newest history appears first and grouping/order remain correct after relaunch
- [ ] Clearing or deleting history only removes the intended records
- [ ] Shared history reads remain consistent between host app and keyboard bridge contracts
- [ ] Schema/storage changes preserve older history data or ship with explicit migration handling

## Settings persistence and shared App Group state

- [ ] Settings persist across relaunch
- [ ] Keyboard-related preferences and selected model are readable from the shared store
- [ ] Invalid or missing App Group configuration fails loudly and recoverably
- [ ] SwiftUI settings changes do not leave stale or contradictory state in the Models/History screens

## Local model lifecycle

- [ ] Install, update, and remove actions leave manifest state internally consistent
- [ ] Unknown model IDs or interrupted actions do not corrupt existing model metadata
- [ ] The selected model falls back safely if an active model is removed
- [ ] Download/update UI and persistence stay aligned after retries or app restarts

## Keyboard-extension-critical paths

- [ ] Keyboard flows depend on shared history/settings handoff rather than unsupported live microphone capture
- [ ] Most-recent transcript handoff returns the expected records in newest-first order
- [ ] Keyboard enable/setup instructions match the actual iOS Settings flow
- [ ] Quick actions and keyboard affordances reflect the shared settings snapshot accurately

## SwiftUI shell regression checks

- [ ] Tab/navigation state stays stable across History, Models, and Settings
- [ ] History/model/settings screens update immediately after state mutations
- [ ] Empty states, destructive actions, and recommended-model affordances still appear when expected
- [ ] Large installed-model payloads and recommended-download states display correct summary metrics

## Notes for the current repository state

This repo currently contains scaffolding and sample-state implementations. As the real host-app transcription engine, persistence layer, and keyboard target land, extend this checklist with device-level verification steps for interruption handling, low-storage behavior, accessibility, and end-to-end insertion into host apps.
