# Sonarus architecture spike

## Status
- Repository state at spike time: the remote repository was empty, so there was no preexisting Xcode project, target layout, entitlement setup, or CI to inspect.
- Result: this spike establishes the target architecture, domain model, and a portable `SonarusCore` package skeleton that the app and keyboard extension can share once the iOS project is scaffolded.

## Product constraints that shape the architecture
1. **A systemwide custom keyboard cannot perform live dictation directly.** Apple’s Custom Keyboard guide states that custom keyboards have no access to the device microphone, so dictation input is not possible from the extension itself. The keyboard can still insert text, read and write a shared app-group container when open access is enabled, and present recent history/settings affordances via shared state.
2. **On-device speech requires capability detection and fallback logic.** The modern Speech stack centers on `SpeechAnalyzer`, `SpeechTranscriber`, `DictationTranscriber`, and `AssetInventory`; older and wider-compatibility flows still use `SFSpeechRecognizer` plus `SFSpeechAudioBufferRecognitionRequest`.
3. **Shared state belongs in an App Group.** The containing app and the custom keyboard extension can share files and `UserDefaults` through an app-group entitlement and shared container.

## Recommended target layout

### 1) SonarusApp (SwiftUI app target)
Responsibilities:
- Request microphone + speech permissions.
- Capture live audio with `AVAudioEngine` or `AVCaptureSession`.
- Run transcription sessions.
- Manage downloadable/offline speech assets.
- Own history browsing, settings, and model-management UI.
- Publish small, extension-safe snapshots into the app-group container.

### 2) SonarusKeyboardExtension (custom keyboard target)
Responsibilities:
- Insert text into the active `UITextDocumentProxy`.
- Read recent history and user settings from the app-group container.
- Offer quick actions such as paste most recent transcript, paste snippets, delete/backspace, and launch the containing app for recording.
- Never attempt to own microphone capture.

### 3) SonarusCore (shared framework / Swift package)
Responsibilities:
- Domain models.
- App-group path resolution.
- Shared storage abstractions.
- Transcription pipeline interfaces.
- Model catalog abstractions.
- Permission abstractions.
- Keyboard bridge contracts.

## Service boundaries

### `PermissionsCoordinator`
Normalizes permission checks and requests for:
- microphone
- speech recognition

Why this matters:
- The host app owns permission prompts and records a small permission snapshot for UI state.
- The keyboard extension only reads the snapshot and offers a handoff path back to the app when permissions are missing.

### `TranscriptionEngine`
A protocol-driven boundary so the app can swap implementations:
- `SpeechAnalyzerEngine` for the newer Speech stack.
- `SpeechRecognizerFallbackEngine` for compatibility workflows built on `SFSpeechRecognizer`.
- `StubTranscriptionEngine` for previews/tests.

Expected behavior:
- Accept a `TranscriptionRequest`.
- Emit async state/partial/final events.
- Stop cleanly.
- Surface whether a final transcript is safe to persist.

### `SpeechModelManager`
Owns local model discovery/install/remove.
- Source of truth for user-visible model availability.
- Bridges Apple-managed speech assets into Sonarus domain models.
- Can persist a light manifest for extension/UI rendering.

### `HistoryStore`
Persists final transcripts and metadata.
- App target is the primary writer.
- Keyboard extension is a reader and occasional consumer.
- Current skeleton uses JSON for portability and easy testing.
- Production implementation can evolve to SwiftData/Core Data in the app-group container once the app target exists.

### `SettingsStore`
Stores cross-target preferences in app-group `UserDefaults`.
Suggested payload:
- preferred locale
- selected model identifier
- save-history enabled
- formatting preferences
- haptics preference
- keyboard-facing presentation settings

### `KeyboardBridge`
Read-only façade the extension uses to access:
- recent transcript history
- settings snapshot

Later extensions:
- pinned snippets
- favorite phrases
- queued insertion actions

## Data model proposal

### `TranscriptionRecord`
Core persisted history object.
- `id: UUID`
- `createdAt: Date`
- `localeIdentifier: String`
- `source: hostApp | keyboardExtension | importedAudio`
- `text: String`
- `duration: TimeInterval`
- `segments: [TranscriptionSegment]`
- `modelIdentifier: String?`
- `metadata: [String: String]`

### `TranscriptionSegment`
Useful for partial results, playback alignment, or future editing.
- `text`
- `startTime`
- `duration`
- `isFinal`

### `SpeechModelDescriptor`
User-visible model inventory entry.
- `id`
- `displayName`
- `localeIdentifier`
- `storageRequirementBytes`
- `availability: notInstalled | downloading | installed | unavailable`
- `lastUpdatedAt`

### `UserPreferences`
Cross-target settings payload.
- `preferredLocaleIdentifier`
- `automaticallyCapitalize`
- `hapticsEnabled`
- `saveHistory`
- `keepScreenAwakeDuringRecording`
- `preferredModelIdentifier`

## Frameworks and packages

### Apple frameworks
- `SwiftUI` for app/settings/history UI
- `UIKit` for `UIInputViewController` keyboard extension
- `AVFoundation` for microphone capture in the host app
- `Speech` for `SpeechAnalyzer`, `SpeechTranscriber`, `DictationTranscriber`, `AssetInventory`, and `SFSpeechRecognizer`
- `Foundation` for shared storage, async streams, JSON persistence, and app-group access
- `OSLog` for structured diagnostics
- `SwiftData` or Core Data later if the team decides to move history off JSON

### Suggested module split in Xcode
- `SonarusApp`
- `SonarusKeyboardExtension`
- `SonarusCore` framework target or Swift package target
- `SonarusAppTests`
- `SonarusCoreTests`

## Persistence recommendation

### Short term
Use:
- app-group `UserDefaults` for settings
- app-group JSON files for history snapshots and model manifest snapshots

Benefits:
- easy cross-target reads
- low setup cost
- straightforward testability
- minimal schema friction while the product surface is still moving

### Medium term
Promote history to SwiftData/Core Data in the shared container if:
- history grows large
- full-text search and filtering become important
- transcript editing/versioning becomes a requirement

If the team takes that path, keep the keyboard extension on a **read-optimized snapshot** rather than making the extension a heavy concurrent writer.

## Recommended recording flows

### Flow A — main app live transcription
1. User opens Sonarus app.
2. App checks permissions.
3. App captures microphone audio.
4. App chooses best engine:
   - advanced offline engine when device + locale + assets support it
   - fallback speech recognizer otherwise
5. Partial results update the live UI.
6. Final transcript is written to history.
7. Recent-history snapshot is immediately available to the keyboard through the shared container.

### Flow B — keyboard quick insert
1. User opens the Sonarus custom keyboard in another app.
2. Keyboard reads recent transcripts and settings from the app group.
3. User taps a recent transcript.
4. Keyboard inserts text through `UITextDocumentProxy`.
5. If user wants fresh dictation, keyboard deep-links into the containing app to record there.

## Major implementation risks
1. **Keyboard microphone limitation**
   - This is a hard platform constraint, not an implementation detail.
   - Mitigation: make the keyboard a consumer of transcripts, not the recorder.

2. **Speech API fragmentation across OS/device capability**
   - Newer APIs and downloadable assets may not be available uniformly.
   - Mitigation: capability probing, engine selection, and graceful fallback.

3. **Shared-container concurrency**
   - App and extension may access the same files concurrently.
   - Mitigation: keep settings small, use atomic writes, prefer single-writer ownership for history, and introduce snapshots when needed.

4. **Privacy and permission sequencing**
   - Permission prompts must happen only when the user is about to use the feature.
   - Mitigation: centralize authorization flow in the host app and surface clear keyboard handoff UX.

5. **Repository bootstrap risk**
   - With no existing iOS project, entitlements, target membership, signing, CI, and Info.plist privacy keys still need to be created.
   - Mitigation: land `SonarusCore` first, then scaffold app + keyboard targets around it.

## What was implemented in this spike
- A new portable `SonarusCore` package skeleton.
- Shared domain models for transcripts, model inventory, and settings.
- App-group container resolution helpers.
- JSON-backed history and model-manifest stores.
- App-group `UserDefaults` settings store.
- Protocol-driven transcription/model/permission boundaries.
- Basic tests covering shared storage behavior.

## Immediate next steps for the team
1. Scaffold the Xcode workspace and iOS app target.
2. Add the custom keyboard extension target with `RequestsOpenAccess = YES` only if shared-container features are needed.
3. Add app-group entitlements to both targets.
4. Add `NSSpeechRecognitionUsageDescription` and `NSMicrophoneUsageDescription` to the app target.
5. Implement a real host-app transcription engine and audio capture service.
6. Build keyboard UI around the shared `KeyboardBridge` contracts.
