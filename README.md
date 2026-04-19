# Sonarus iOS

A native SwiftUI shell for configuring local speech-to-text models, reviewing transcription history, and managing keyboard-extension integration.

## Project layout

- `Sonarus/App` — app entry point
- `Sonarus/Features` — tab-driven feature screens
- `Sonarus/State` — shared `AppState` for local UI state and sample data
- `Sonarus/Shared` — reusable UI building blocks, styles, and domain models
- `SonarusTests` — lightweight state and behavior tests

## Getting started

This repository ships with an `XcodeGen` spec so the project can be generated consistently.

1. Install XcodeGen on macOS.
2. Run `xcodegen generate` from the repository root.
3. Open the generated `Sonarus.xcodeproj` in Xcode.
4. Build and run the `Sonarus` scheme.

## Testing

The repository currently has two automated layers:

1. **`swift test`** for `SonarusCore` storage, model-management, keyboard-bridge, permissions, and transcription stub coverage.
2. **Xcode/XcodeGen-based app tests** for `AppState` and the SwiftUI shell scaffolding.

Typical commands on macOS:

```bash
swift test
xcodegen generate
xcodebuild -project Sonarus.xcodeproj -scheme Sonarus -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build-for-testing
```

Release verification guidance for permissions, offline behavior, history correctness, settings persistence, model lifecycle, and keyboard-critical paths lives in `docs/release-verification-checklist.md`.

## Product direction

The initial shell focuses on three tabs:

1. **History** — searchable/pinnable transcription history and capture summaries.
2. **Models** — local model inventory, activation, and keyboard-extension readiness.
3. **Settings** — dictation behavior, privacy defaults, and keyboard quick actions.

The data is currently backed by sample state so the team can iterate on the UI and wiring before backend/local persistence lands.
