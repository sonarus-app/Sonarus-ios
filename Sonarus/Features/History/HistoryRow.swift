import SwiftUI

struct HistoryRow: View {
    let record: TranscriptionRecord
    let onPinToggle: () -> Void

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            StatusBadge(title: record.source.label, tint: record.source.tint)

                            if record.isPinned {
                                StatusBadge(title: "Pinned", tint: .yellow)
                            }
                        }

                        Text(record.text)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 0)

                    Button(action: onPinToggle) {
                        Image(systemName: record.isPinned ? "pin.fill" : "pin")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(record.isPinned ? .yellow : .secondary)
                            .padding(10)
                            .background(AppTheme.surfaceMuted, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(record.isPinned ? "Unpin transcript" : "Pin transcript")
                }

                HStack(spacing: 8) {
                    Label(record.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                    Label(record.duration.formatted(.units(allowed: [.minutes, .seconds], width: .abbreviated)), systemImage: "waveform")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !record.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(record.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(AppTheme.accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.accent.opacity(0.12), in: Capsule())
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    HistoryRow(record: .samples[0]) {}
        .padding()
}
