import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.historySections.isEmpty {
                EmptyStateView(
                    systemImage: "waveform.badge.magnifyingglass",
                    title: "No saved transcripts yet",
                    message: "Transcripts created from the keyboard or microphone will appear here. Pin important snippets so they survive quick cleanup."
                )
                .padding(.horizontal, 20)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        overviewCard

                        ForEach(appState.historySections) { section in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(section.title)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 4)

                                VStack(spacing: 12) {
                                    ForEach(section.items) { item in
                                        HistoryRow(record: item) {
                                            appState.togglePinned(for: item.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .background(AppTheme.canvas.ignoresSafeArea())
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !appState.historyRecords.isEmpty {
                    Button("Clear Unpinned", role: .destructive) {
                        appState.clearUnpinnedHistory()
                    }
                }
            }
        }
    }

    private var overviewCard: some View {
        SectionCard(
            title: "Recent activity",
            subtitle: "Everything stays local-first and ready for reuse inside the keyboard extension."
        ) {
            HStack(spacing: 12) {
                metric(title: "Saved", value: "\(appState.historyRecords.count)")
                metric(title: "Pinned", value: "\(appState.pinnedHistoryCount)")
                metric(title: "Active Model", value: appState.activeModel?.name ?? "None")
            }
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .environmentObject(AppState.preview)
    }
}
