import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Capture behavior") {
                Toggle("Auto-copy latest transcript", isOn: $appState.settings.autoCopyLatestTranscript)
                Toggle("Insert transcript immediately after dictation", isOn: $appState.settings.automaticallyInsertAfterTranscription)

                Picker("Preferred capture mode", selection: $appState.settings.preferredCaptureMode) {
                    ForEach(CaptureMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
            } footer: {
                Text("These preferences should be shared with the keyboard extension through a common app group store.")
            }

            Section("Privacy") {
                Toggle("Store audio clips for QA review", isOn: $appState.settings.saveAudioClips)
                Toggle("Keep transcripts on-device only", isOn: $appState.settings.keepTranscriptsOnDeviceOnly)

                Picker("Appearance", selection: $appState.settings.theme) {
                    ForEach(AppThemePreference.allCases) { theme in
                        Text(theme.title).tag(theme)
                    }
                }
            }

            Section("Keyboard integration") {
                TextField("App group identifier", text: $appState.settings.keyboard.appGroupIdentifier)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Toggle("Enable pasteboard bridge", isOn: $appState.settings.keyboard.pasteboardBridgeEnabled)
                Toggle("Show open-app shortcut", isOn: $appState.settings.keyboard.openHostAppShortcutEnabled)
            } footer: {
                Text("Use the host app as the place to manage models, entitlement-backed settings, and detailed history browsing.")
            }

            Section("Keyboard quick actions") {
                ForEach(KeyboardQuickAction.allCases) { action in
                    Button {
                        appState.toggleQuickAction(action)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(action.title)
                                    .foregroundStyle(.primary)
                                Text(action.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: appState.settings.keyboard.quickActions.contains(action) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(appState.settings.keyboard.quickActions.contains(action) ? AppTheme.accent : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                Text("Quick actions are the lightweight commands rendered above the custom keyboard.")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppState.preview)
    }
}
