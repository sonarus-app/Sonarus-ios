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

    func testClearUnpinnedHistoryPreservesPinnedItems() {
        let state = AppState.preview

        state.clearUnpinnedHistory()

        XCTAssertEqual(state.historyRecords.count, 1)
        XCTAssertTrue(state.historyRecords.allSatisfy(\.isPinned))
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
}
