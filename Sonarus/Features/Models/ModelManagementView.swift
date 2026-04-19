import SwiftUI

struct ModelManagementView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                activeModelCard
                storageCard
                keyboardExtensionCard

                VStack(alignment: .leading, spacing: 12) {
                    Text("Available models")
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, 4)

                    ForEach(appState.models) { model in
                        modelCard(model)
                    }
                }
            }
            .padding(20)
        }
        .background(AppTheme.canvas.ignoresSafeArea())
        .navigationTitle("Models")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !appState.recommendedModelsPending.isEmpty {
                    Button("Install Recommended") {
                        appState.installRecommendedModels()
                    }
                }
            }
        }
    }

    private var activeModelCard: some View {
        SectionCard(
            title: "Active transcription path",
            subtitle: "The selected model is shared by the app and the keyboard extension configuration."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appState.activeModel?.name ?? "No active model")
                            .font(.headline)
                        Text(appState.activeModel?.locale ?? "Choose a local model to enable dictation")
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    if let activeModel = appState.activeModel {
                        StatusBadge(title: activeModel.installState.badgeTitle, tint: activeModel.installState.tint)
                    }
                }

                Text(appState.keyboardReadinessSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var storageCard: some View {
        SectionCard(title: "Storage", subtitle: "Keep an eye on downloaded on-device models and update windows.") {
            HStack(spacing: 12) {
                storageMetric(title: "Downloaded", value: appState.totalDownloadedModelSizeLabel)
                storageMetric(title: "Installed", value: "\(appState.installedModelCount)")
                storageMetric(title: "Need action", value: "\(appState.modelsNeedingAttention.count)")
            }
        }
    }

    private func storageMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var keyboardExtensionCard: some View {
        SectionCard(title: "Keyboard extension", subtitle: "Plan for app-group state sharing and one-tap entry points.") {
            VStack(alignment: .leading, spacing: 10) {
                Label(appState.settings.keyboard.appGroupIdentifier, systemImage: "externaldrive.badge.icloud")
                    .foregroundStyle(.primary)

                Label(
                    appState.settings.keyboard.openHostAppShortcutEnabled ? "Host app launch shortcut enabled" : "Host app launch shortcut disabled",
                    systemImage: appState.settings.keyboard.openHostAppShortcutEnabled ? "arrow.up.forward.app.fill" : "arrow.up.forward.app"
                )
                .foregroundStyle(.secondary)

                Label(
                    appState.settings.keyboard.pasteboardBridgeEnabled ? "Pasteboard handoff enabled" : "Pasteboard handoff disabled",
                    systemImage: appState.settings.keyboard.pasteboardBridgeEnabled ? "doc.on.clipboard.fill" : "doc.on.clipboard"
                )
                .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
    }

    private func modelCard(_ model: LocalSpeechModel) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(model.name)
                                .font(.headline)

                            if model.isRecommended {
                                StatusBadge(title: "Recommended", tint: .green)
                            }

                            if model.isActive {
                                StatusBadge(title: "Active", tint: AppTheme.accent)
                            }
                        }

                        Text("\(model.locale) • \(model.sizeInMB) MB • \(model.latencyLabel) latency")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("Accuracy target: \(model.accuracyLabel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    StatusBadge(title: model.installState.badgeTitle, tint: model.installState.tint)
                }

                if case let .downloading(progress) = model.installState {
                    ProgressView(value: progress)
                        .tint(AppTheme.accent)
                }

                HStack {
                    Text(model.lastUsedAt.map { "Last used \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "Not used yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 0)

                    Button(model.installState.primaryActionTitle(isActive: model.isActive)) {
                        appState.performPrimaryModelAction(for: model.id)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                    .disabled(model.isActive && model.installState == .installed)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ModelManagementView()
            .environmentObject(AppState.preview)
    }
}
