import XCTest
@testable import Sonarus

final class AppStateTests: XCTestCase {
    func testPerformPrimaryModelActionMakesChosenModelActive() {
        let state = AppState.preview
        let targetID = LocalSpeechModel.samples[2].id

        state.performPrimaryModelAction(for: targetID)

        XCTAssertEqual(state.activeModel?.id, targetID)
        XCTAssertEqual(state.models.filter(\.isActive).count, 1)
        XCTAssertEqual(state.models.first(where: { $0.id == targetID })?.installState, .installed)
    }

    func testPerformPrimaryModelActionStartsDownloadForNotInstalledModelWithoutChangingActiveModel() {
        let state = AppState.preview
        let originalActiveModelID = state.activeModel?.id
        let targetID = LocalSpeechModel.samples[1].id

        state.performPrimaryModelAction(for: targetID)

        XCTAssertEqual(state.activeModel?.id, originalActiveModelID)
        XCTAssertEqual(state.models.first(where: { $0.id == targetID })?.installState, .downloading(progress: 0.55))
    }

    func testClearUnpinnedHistoryPreservesPinnedItems() {
        let state = AppState.preview

        state.clearUnpinnedHistory()

        XCTAssertEqual(state.historyRecords.count, 1)
        XCTAssertTrue(state.historyRecords.allSatisfy(\.isPinned))
    }

    func testTogglePinnedOnlyChangesRequestedRecord() {
        let state = AppState.preview
        let targetID = TranscriptionRecord.samples[1].id

        state.togglePinned(for: targetID)

        XCTAssertTrue(state.historyRecords.first(where: { $0.id == targetID })?.isPinned == true)
        XCTAssertEqual(state.pinnedHistoryCount, 2)
        XCTAssertTrue(state.historyRecords.first(where: { $0.id == TranscriptionRecord.samples[0].id })?.isPinned == true)
    }

    func testToggleQuickActionAddsThenRemovesSelection() {
        let state = AppState.preview

        XCTAssertFalse(state.settings.keyboard.quickActions.contains(.openHistory))

        state.toggleQuickAction(.openHistory)
        XCTAssertTrue(state.settings.keyboard.quickActions.contains(.openHistory))

        state.toggleQuickAction(.openHistory)
        XCTAssertFalse(state.settings.keyboard.quickActions.contains(.openHistory))
    }

    func testInstallRecommendedModelsStartsDownloadsForMissingRecommendedModels() {
        let state = AppState.preview
        let targetID = LocalSpeechModel.samples[1].id

        state.installRecommendedModels()

        XCTAssertEqual(state.models.first(where: { $0.id == targetID })?.installState, .downloading(progress: 0.35))
    }

    func testHistorySectionsGroupRecordsByDayAndKeepNewestItemsFirst() {
        let calendar = Calendar.current
        let now = Date()
        let todayRecent = makeRecord(id: "44444444-4444-4444-4444-444444444444", createdAt: now.addingTimeInterval(-300), text: "Recent today")
        let todayOlder = makeRecord(id: "55555555-5555-5555-5555-555555555555", createdAt: now.addingTimeInterval(-1_800), text: "Older today")
        let yesterday = makeRecord(
            id: "66666666-6666-6666-6666-666666666666",
            createdAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now.addingTimeInterval(-86_400),
            text: "Yesterday"
        )
        let state = AppState(
            selectedTab: .history,
            historyRecords: [todayOlder, yesterday, todayRecent],
            models: LocalSpeechModel.samples,
            settings: .sample
        )

        let sections = state.historySections

        XCTAssertEqual(Array(sections.prefix(2).map(\.title)), ["Today", "Yesterday"])
        XCTAssertEqual(sections.first?.items.map(\.text), ["Recent today", "Older today"])
    }

    func testKeyboardReadinessSummaryPluralizesQuickActions() {
        let state = AppState.preview

        state.settings.keyboard.quickActions = [.startDictation]
        XCTAssertTrue(state.keyboardReadinessSummary.contains("1 quick action configured."))

        state.settings.keyboard.quickActions = [.startDictation, .openHistory]
        XCTAssertTrue(state.keyboardReadinessSummary.contains("2 quick actions configured."))
    }

    func testTotalDownloadedModelSizeLabelUsesGigabytesForLargeInstalledFootprint() {
        let state = AppState(
            selectedTab: .models,
            historyRecords: [],
            models: [
                makeModel(id: "77777777-7777-7777-7777-777777777777", sizeInMB: 1024, installState: .installed, isActive: true),
                makeModel(id: "88888888-8888-8888-8888-888888888888", sizeInMB: 1024, installState: .updateAvailable, isActive: false)
            ],
            settings: .sample
        )

        XCTAssertEqual(state.totalDownloadedModelSizeLabel, "2.0 GB")
    }
}

private func makeRecord(id: String, createdAt: Date, text: String) -> TranscriptionRecord {
    TranscriptionRecord(
        id: UUID(uuidString: id)!,
        createdAt: createdAt,
        duration: 15,
        text: text,
        source: .keyboard,
        tags: [],
        isPinned: false
    )
}

private func makeModel(id: String, sizeInMB: Int, installState: ModelInstallState, isActive: Bool) -> LocalSpeechModel {
    LocalSpeechModel(
        id: UUID(uuidString: id)!,
        name: "Model \(sizeInMB)",
        locale: "English (US)",
        sizeInMB: sizeInMB,
        latencyLabel: "Fast",
        accuracyLabel: "High",
        isRecommended: false,
        isActive: isActive,
        installState: installState,
        lastUsedAt: nil
    )
}
