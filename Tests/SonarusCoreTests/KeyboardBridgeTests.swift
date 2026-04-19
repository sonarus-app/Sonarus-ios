import Foundation
import Testing
@testable import SonarusCore

@Suite("SharedKeyboardBridge")
struct SharedKeyboardBridgeTests {
    @Test("mostRecentTranscriptions returns newest-first history trimmed to the requested limit")
    func mostRecentTranscriptionsHonorsLimit() async throws {
        let history = [
            makeRecord(text: "Newest", createdAt: Date(timeIntervalSince1970: 30)),
            makeRecord(text: "Middle", createdAt: Date(timeIntervalSince1970: 20)),
            makeRecord(text: "Oldest", createdAt: Date(timeIntervalSince1970: 10))
        ]
        let bridge = SharedKeyboardBridge(
            historyStore: InMemoryHistoryStore(records: history),
            settingsStore: StaticSettingsStore(preferences: UserPreferences(preferredLocaleIdentifier: "en_US"))
        )

        let recent = try await bridge.mostRecentTranscriptions(limit: 2)

        #expect(recent.map(\.text) == ["Newest", "Middle"])
    }

    @Test("settingsSnapshot surfaces the latest shared preferences for keyboard consumers")
    func settingsSnapshotReturnsSharedPreferences() {
        let preferences = UserPreferences(
            preferredLocaleIdentifier: "es_ES",
            automaticallyCapitalize: false,
            hapticsEnabled: false,
            saveHistory: false,
            keepScreenAwakeDuringRecording: false,
            preferredModelIdentifier: "offline.es-ES"
        )
        let bridge = SharedKeyboardBridge(
            historyStore: InMemoryHistoryStore(records: []),
            settingsStore: StaticSettingsStore(preferences: preferences)
        )

        #expect(bridge.settingsSnapshot() == preferences)
    }
}

@Suite("StubPermissionsCoordinator")
struct StubPermissionsCoordinatorTests {
    @Test("currentStatus and requestPermissions return the configured authorization snapshot")
    func returnsConfiguredSnapshot() async {
        let expected = PermissionSnapshot(speechRecognition: .authorized, microphone: .denied)
        let coordinator = StubPermissionsCoordinator(snapshot: expected)

        let current = await coordinator.currentStatus()
        let requested = await coordinator.requestPermissions()

        #expect(current == expected)
        #expect(requested == expected)
    }
}

@Suite("StubTranscriptionEngine")
struct StubTranscriptionEngineTests {
    @Test("start yields scripted events in order")
    func startYieldsScriptedEvents() async throws {
        let expectedRecord = TranscriptionRecord(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            createdAt: Date(timeIntervalSince1970: 123),
            localeIdentifier: "en_US",
            source: .hostApp,
            text: "hello world",
            duration: 1.5
        )
        let expectedEvents: [TranscriptionEvent] = [
            .preparing,
            .listening,
            .partial(TranscriptionSegment(text: "hello", startTime: 0, duration: 0.5, isFinal: false)),
            .final(expectedRecord)
        ]
        let engine = StubTranscriptionEngine(kind: .advancedOffline, scriptedEvents: expectedEvents)

        var actualEvents: [TranscriptionEvent] = []
        for try await event in engine.start(request: TranscriptionRequest(localeIdentifier: "en_US")) {
            actualEvents.append(event)
        }

        #expect(actualEvents == expectedEvents)
    }
}

private actor InMemoryHistoryStore: HistoryStoring {
    private var records: [TranscriptionRecord]

    init(records: [TranscriptionRecord]) {
        self.records = records
    }

    func loadHistory() async throws -> [TranscriptionRecord] {
        records
    }

    func append(_ record: TranscriptionRecord) async throws {
        records.insert(record, at: 0)
    }

    func removeAll() async throws {
        records.removeAll()
    }
}

private struct StaticSettingsStore: SettingsStoring {
    let preferences: UserPreferences

    func load() -> UserPreferences {
        preferences
    }

    func save(_ preferences: UserPreferences) throws {}
}

private func makeRecord(text: String, createdAt: Date) -> TranscriptionRecord {
    TranscriptionRecord(
        createdAt: createdAt,
        localeIdentifier: "en_US",
        source: .keyboardExtension,
        text: text,
        duration: 1
    )
}
