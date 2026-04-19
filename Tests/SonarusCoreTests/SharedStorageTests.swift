import Foundation
import Testing
@testable import SonarusCore

@Suite("JSONHistoryStore")
struct JSONHistoryStoreTests {
    @Test("append writes newest-first history and enforces retention")
    func appendOrdersAndTrimsHistory() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let configuration = AppGroupConfiguration(identifier: "group.test.sonarus", historyFilename: "history.json")
        let store = JSONHistoryStore(
            configuration: configuration,
            resolver: StaticContainerResolver(rootURL: directory),
            maxRecordCount: 2
        )

        try await store.append(.init(localeIdentifier: "en_US", source: .hostApp, text: "one", duration: 1))
        try await store.append(.init(localeIdentifier: "en_US", source: .hostApp, text: "two", duration: 2))
        try await store.append(.init(localeIdentifier: "en_US", source: .hostApp, text: "three", duration: 3))

        let history = try await store.loadHistory()
        #expect(history.map(\.text) == ["three", "two"])

        let fileURL = directory.appending(path: configuration.historyFilename, directoryHint: .notDirectory)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope = try decoder.decode(HistoryFileEnvelope.self, from: Data(contentsOf: fileURL))
        #expect(envelope.schemaVersion == AppGroupSchemaVersion.current)
        #expect(envelope.records.map(\.text) == ["three", "two"])
    }

    @Test("loadHistory migrates legacy raw arrays into a versioned envelope")
    func migratesLegacyHistoryFile() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let configuration = AppGroupConfiguration(identifier: "group.test.sonarus", historyFilename: "history.json")
        let record = TranscriptionRecord(
            localeIdentifier: "en_US",
            source: .hostApp,
            text: "legacy",
            duration: 4,
            tags: ["Pinned"],
            isPinned: true
        )
        let fileURL = directory.appending(path: configuration.historyFilename, directoryHint: .notDirectory)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let legacyData = try encoder.encode([record])
        try legacyData.write(to: fileURL, options: .atomic)

        let store = JSONHistoryStore(
            configuration: configuration,
            resolver: StaticContainerResolver(rootURL: directory)
        )

        let loaded = try await store.loadHistory()
        #expect(loaded == [record])

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope = try decoder.decode(HistoryFileEnvelope.self, from: Data(contentsOf: fileURL))
        #expect(envelope.schemaVersion == AppGroupSchemaVersion.current)
        #expect(envelope.records == [record])
    }

    @Test("saveHistory and removeRecord support whole-list updates")
    func saveHistoryAndRemoveRecord() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let configuration = AppGroupConfiguration(identifier: "group.test.sonarus")
        let store = JSONHistoryStore(configuration: configuration, resolver: StaticContainerResolver(rootURL: directory))
        let first = TranscriptionRecord(localeIdentifier: "en_US", source: .hostApp, text: "first", duration: 1)
        let second = TranscriptionRecord(localeIdentifier: "en_US", source: .keyboardExtension, text: "second", duration: 2)

        try await store.saveHistory([first, second])
        try await store.removeRecord(withID: first.id)

        let history = try await store.loadHistory()
        #expect(history == [second])
    }

    @Test("removeAll clears persisted file")
    func removeAll() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let configuration = AppGroupConfiguration(identifier: "group.test.sonarus")
        let store = JSONHistoryStore(configuration: configuration, resolver: StaticContainerResolver(rootURL: directory))
        try await store.append(.init(localeIdentifier: "en_US", source: .hostApp, text: "sample", duration: 1))

        try await store.removeAll()

        let history = try await store.loadHistory()
        #expect(history.isEmpty)
    }
}

@Suite("SharedAppGroupDataStore")
struct SharedAppGroupDataStoreTests {
    @Test("loadSnapshot composes history, preferences, and model manifests")
    func loadSnapshot() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let configuration = AppGroupConfiguration(identifier: "group.test.sonarus")
        let historyStore = JSONHistoryStore(configuration: configuration, resolver: StaticContainerResolver(rootURL: directory))
        let settingsStore = UserDefaultsSettingsStore(
            configuration: configuration,
            userDefaults: try #require(UserDefaults(suiteName: "sonarus.snapshot.\(UUID().uuidString)"))
        )
        let modelStore = JSONSpeechModelManifestStore(configuration: configuration, resolver: StaticContainerResolver(rootURL: directory))
        let model = SpeechModelDescriptor(
            id: "offline.en-US",
            displayName: "English Offline",
            localeIdentifier: "en_US",
            storageRequirementBytes: 1_024,
            availability: .installed,
            lastUpdatedAt: Date(timeIntervalSince1970: 123)
        )
        let preferences = UserPreferences(
            preferredLocaleIdentifier: "en_US",
            keyboard: KeyboardPreferences(appGroupIdentifier: configuration.identifier, quickActions: [.startDictation, .pasteLatestTranscript])
        )
        let record = TranscriptionRecord(localeIdentifier: "en_US", source: .hostApp, text: "snapshot", duration: 3)

        try await historyStore.saveHistory([record])
        try settingsStore.save(preferences)
        try await modelStore.saveManifest([model])

        let store = SharedAppGroupDataStore(
            historyStore: historyStore,
            settingsStore: settingsStore,
            modelManifestStore: modelStore
        )

        let snapshot = try await store.loadSnapshot()
        #expect(snapshot.history == [record])
        #expect(snapshot.preferences == preferences)
        #expect(snapshot.models == [model])
    }
}
