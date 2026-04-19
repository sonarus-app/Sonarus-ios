import Foundation
import SwiftUI

final class AppState: ObservableObject {
    struct HistorySection: Identifiable, Equatable {
        let id: String
        let title: String
        let items: [TranscriptionRecord]
    }

    @Published var selectedTab: AppTab
    @Published var historyRecords: [TranscriptionRecord]
    @Published var models: [LocalSpeechModel]
    @Published var settings: UserSettings

    init(
        selectedTab: AppTab = .history,
        historyRecords: [TranscriptionRecord],
        models: [LocalSpeechModel],
        settings: UserSettings
    ) {
        self.selectedTab = selectedTab
        self.historyRecords = historyRecords
        self.models = models
        self.settings = settings
    }

    var activeModel: LocalSpeechModel? {
        models.first(where: \.isActive)
    }

    var pinnedHistoryCount: Int {
        historyRecords.filter(\.isPinned).count
    }

    var installedModelCount: Int {
        models.filter { $0.installState.countsAsInstalled }.count
    }

    var modelsNeedingAttention: [LocalSpeechModel] {
        models.filter {
            $0.installState == .notInstalled || $0.installState == .updateAvailable
        }
    }

    var recommendedModelsPending: [LocalSpeechModel] {
        models.filter {
            $0.isRecommended && $0.installState == .notInstalled
        }
    }

    var totalDownloadedModelSizeLabel: String {
        let totalMB = models
            .filter { $0.installState.countsAsInstalled }
            .reduce(0) { partialResult, model in
                partialResult + model.sizeInMB
            }

        if totalMB >= 1024 {
            let gigabytes = Double(totalMB) / 1024
            return String(format: "%.1f GB", gigabytes)
        }

        return "\(totalMB) MB"
    }

    var keyboardReadinessSummary: String {
        let quickActionCount = settings.keyboard.quickActions.count
        return "App group: \(settings.keyboard.appGroupIdentifier) • \(quickActionCount) quick action\(quickActionCount == 1 ? "" : "s") configured."
    }

    var historySections: [HistorySection] {
        let calendar = Calendar.current
        let sorted = historyRecords.sorted { $0.createdAt > $1.createdAt }
        let grouped = Dictionary(grouping: sorted) { calendar.startOfDay(for: $0.createdAt) }

        return grouped.keys.sorted(by: >).map { date in
            let title: String
            if calendar.isDateInToday(date) {
                title = "Today"
            } else if calendar.isDateInYesterday(date) {
                title = "Yesterday"
            } else {
                title = date.formatted(.dateTime.month(.abbreviated).day())
            }

            return HistorySection(
                id: String(date.timeIntervalSince1970),
                title: title,
                items: grouped[date]?.sorted(by: { $0.createdAt > $1.createdAt }) ?? []
            )
        }
    }

    func togglePinned(for id: UUID) {
        guard let index = historyRecords.firstIndex(where: { $0.id == id }) else { return }
        historyRecords[index].isPinned.toggle()
    }

    func clearUnpinnedHistory() {
        historyRecords.removeAll { !$0.isPinned }
    }

    func performPrimaryModelAction(for id: UUID) {
        guard let index = models.firstIndex(where: { $0.id == id }) else { return }

        switch models[index].installState {
        case .installed:
            setActiveModel(id)
        case .downloading:
            models[index].installState = .installed
            setActiveModel(id)
        case .notInstalled:
            models[index].installState = .downloading(progress: 0.55)
        case .updateAvailable:
            models[index].installState = .installed
            setActiveModel(id)
        }
    }

    func installRecommendedModels() {
        for index in models.indices {
            guard models[index].isRecommended else { continue }
            guard models[index].installState == .notInstalled else { continue }
            models[index].installState = .downloading(progress: 0.35)
        }
    }

    func toggleQuickAction(_ action: KeyboardQuickAction) {
        if settings.keyboard.quickActions.contains(action) {
            settings.keyboard.quickActions.removeAll { $0 == action }
        } else {
            settings.keyboard.quickActions.append(action)
        }
    }

    private func setActiveModel(_ id: UUID) {
        for index in models.indices {
            models[index].isActive = models[index].id == id
        }
    }
}

extension AppState {
    static var preview: AppState {
        AppState(
            selectedTab: .history,
            historyRecords: TranscriptionRecord.samples,
            models: LocalSpeechModel.samples,
            settings: .sample
        )
    }
}
