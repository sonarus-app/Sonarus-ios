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
