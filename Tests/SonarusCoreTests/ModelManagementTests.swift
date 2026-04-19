import Foundation
import Testing
@testable import SonarusCore

@Suite("JSONSpeechModelManifestStore")
struct JSONSpeechModelManifestStoreTests {
    @Test("loadManifest returns an empty array when the manifest file is missing")
    func loadManifestWhenMissing() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let configuration = AppGroupConfiguration(identifier: "group.test.sonarus")
        let store = JSONSpeechModelManifestStore(
            configuration: configuration,
            resolver: StaticContainerResolver(rootURL: directory)
        )

        let manifest = try await store.loadManifest()

        #expect(manifest.isEmpty)
    }

    @Test("saveManifest round trips model descriptors through JSON storage")
    func saveAndLoadManifest() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let configuration = AppGroupConfiguration(identifier: "group.test.sonarus", modelManifestFilename: "manifest.json")
        let store = JSONSpeechModelManifestStore(
            configuration: configuration,
            resolver: StaticContainerResolver(rootURL: directory)
        )
        let expected = [
            SpeechModelDescriptor(
                id: "offline.en-US",
                displayName: "Offline English",
                localeIdentifier: "en_US",
                storageRequirementBytes: 512_000_000,
                availability: .installed,
                lastUpdatedAt: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            SpeechModelDescriptor(
                id: "offline.es-ES",
                displayName: "Offline Spanish",
                localeIdentifier: "es_ES",
                storageRequirementBytes: 768_000_000,
                availability: .downloading,
                lastUpdatedAt: nil
            )
        ]

        try await store.saveManifest(expected)
        let actual = try await store.loadManifest()

        #expect(actual == expected)
    }
}

@Suite("StubSpeechModelManager")
struct StubSpeechModelManagerTests {
    @Test("installModel marks the requested model installed and refreshes its timestamp")
    func installModelUpdatesManifest() async throws {
        let store = InMemoryManifestStore(manifest: [
            makeDescriptor(id: "offline.en-US", availability: .notInstalled),
            makeDescriptor(id: "offline.es-ES", availability: .installed)
        ])
        let manager = StubSpeechModelManager(manifestStore: store)

        try await manager.installModel(withID: "offline.en-US")
        let manifest = try await store.loadManifest()
        let updated = try #require(manifest.first(where: { $0.id == "offline.en-US" }))
        let unchanged = try #require(manifest.first(where: { $0.id == "offline.es-ES" }))

        #expect(updated.availability == .installed)
        #expect(updated.lastUpdatedAt != nil)
        #expect(unchanged.availability == .installed)
    }

    @Test("removeModel marks the requested model as not installed and refreshes its timestamp")
    func removeModelUpdatesManifest() async throws {
        let store = InMemoryManifestStore(manifest: [
            makeDescriptor(id: "offline.en-US", availability: .installed),
            makeDescriptor(id: "offline.fr-FR", availability: .notInstalled)
        ])
        let manager = StubSpeechModelManager(manifestStore: store)

        try await manager.removeModel(withID: "offline.en-US")
        let manifest = try await store.loadManifest()
        let updated = try #require(manifest.first(where: { $0.id == "offline.en-US" }))
        let unchanged = try #require(manifest.first(where: { $0.id == "offline.fr-FR" }))

        #expect(updated.availability == .notInstalled)
        #expect(updated.lastUpdatedAt != nil)
        #expect(unchanged.availability == .notInstalled)
    }

    @Test("unknown model identifiers leave the manifest unchanged")
    func unknownModelIDsAreIgnored() async throws {
        let original = [
            makeDescriptor(id: "offline.en-US", availability: .installed),
            makeDescriptor(id: "offline.es-ES", availability: .notInstalled)
        ]
        let store = InMemoryManifestStore(manifest: original)
        let manager = StubSpeechModelManager(manifestStore: store)

        try await manager.installModel(withID: "missing")
        try await manager.removeModel(withID: "still-missing")
        let manifest = try await store.loadManifest()

        #expect(manifest == original)
    }
}

private actor InMemoryManifestStore: SpeechModelManifestStoring {
    private var manifest: [SpeechModelDescriptor]

    init(manifest: [SpeechModelDescriptor]) {
        self.manifest = manifest
    }

    func loadManifest() async throws -> [SpeechModelDescriptor] {
        manifest
    }

    func saveManifest(_ manifest: [SpeechModelDescriptor]) async throws {
        self.manifest = manifest
    }
}

private func makeDescriptor(id: String, availability: SpeechModelDescriptor.Availability) -> SpeechModelDescriptor {
    SpeechModelDescriptor(
        id: id,
        displayName: id,
        localeIdentifier: "en_US",
        storageRequirementBytes: 256_000_000,
        availability: availability,
        lastUpdatedAt: nil
    )
}
