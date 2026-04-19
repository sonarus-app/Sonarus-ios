import Foundation

public protocol SpeechModelManaging: Sendable {
    func availableModels() async throws -> [SpeechModelDescriptor]
    func installModel(withID id: String) async throws
    func removeModel(withID id: String) async throws
}

public protocol SpeechModelManifestStoring: Sendable {
    func loadManifest() async throws -> [SpeechModelDescriptor]
    func saveManifest(_ manifest: [SpeechModelDescriptor]) async throws
}

public actor JSONSpeechModelManifestStore: SpeechModelManifestStoring {
    private let configuration: AppGroupConfiguration
    private let resolver: SharedContainerResolving
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        configuration: AppGroupConfiguration,
        resolver: SharedContainerResolving,
        fileManager: FileManager = .default
    ) {
        self.configuration = configuration
        self.resolver = resolver
        self.fileManager = fileManager
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func loadManifest() async throws -> [SpeechModelDescriptor] {
        let fileURL = try manifestURL()
        guard fileManager.fileExists(atPath: fileURL.path()) else {
            return []
        }

        return try decoder.decode([SpeechModelDescriptor].self, from: Data(contentsOf: fileURL))
    }

    public func saveManifest(_ manifest: [SpeechModelDescriptor]) async throws {
        let data = try encoder.encode(manifest)
        try data.write(to: try manifestURL(), options: .atomic)
    }

    private func manifestURL() throws -> URL {
        let containerURL = try resolver.containerURL(for: configuration)
        if !fileManager.fileExists(atPath: containerURL.path()) {
            try fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true)
        }
        return containerURL.appending(path: configuration.modelManifestFilename, directoryHint: .notDirectory)
    }
}

public struct StubSpeechModelManager: SpeechModelManaging {
    private let manifestStore: any SpeechModelManifestStoring

    public init(manifestStore: any SpeechModelManifestStoring) {
        self.manifestStore = manifestStore
    }

    public func availableModels() async throws -> [SpeechModelDescriptor] {
        try await manifestStore.loadManifest()
    }

    public func installModel(withID id: String) async throws {
        var manifest = try await manifestStore.loadManifest()
        guard let index = manifest.firstIndex(where: { $0.id == id }) else {
            return
        }
        manifest[index].availability = .installed
        manifest[index].lastUpdatedAt = Date()
        try await manifestStore.saveManifest(manifest)
    }

    public func removeModel(withID id: String) async throws {
        var manifest = try await manifestStore.loadManifest()
        guard let index = manifest.firstIndex(where: { $0.id == id }) else {
            return
        }
        manifest[index].availability = .notInstalled
        manifest[index].lastUpdatedAt = Date()
        try await manifestStore.saveManifest(manifest)
    }
}
