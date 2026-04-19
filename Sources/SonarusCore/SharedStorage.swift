import Foundation

public enum AppGroupSchemaVersion {
    public static let current = 2
}

public struct HistoryFileEnvelope: Codable, Hashable, Sendable {
    public var schemaVersion: Int
    public var records: [TranscriptionRecord]

    public init(
        schemaVersion: Int = AppGroupSchemaVersion.current,
        records: [TranscriptionRecord]
    ) {
        self.schemaVersion = schemaVersion
        self.records = records
    }
}

public struct SettingsEnvelope: Codable, Hashable, Sendable {
    public var schemaVersion: Int
    public var preferences: UserPreferences

    public init(
        schemaVersion: Int = AppGroupSchemaVersion.current,
        preferences: UserPreferences
    ) {
        self.schemaVersion = schemaVersion
        self.preferences = preferences
    }
}

public struct SharedAppGroupSnapshot: Hashable, Sendable {
    public var history: [TranscriptionRecord]
    public var preferences: UserPreferences
    public var models: [SpeechModelDescriptor]

    public init(
        history: [TranscriptionRecord],
        preferences: UserPreferences,
        models: [SpeechModelDescriptor] = []
    ) {
        self.history = history
        self.preferences = preferences
        self.models = models
    }
}

public protocol HistoryStoring: Sendable {
    func loadHistory() async throws -> [TranscriptionRecord]
    func saveHistory(_ records: [TranscriptionRecord]) async throws
    func append(_ record: TranscriptionRecord) async throws
    func upsert(_ record: TranscriptionRecord) async throws
    func removeRecord(withID id: UUID) async throws
    func removeAll() async throws
}

public protocol SettingsStoring: Sendable {
    func load() -> UserPreferences
    func save(_ preferences: UserPreferences) throws
    func reset() throws
}

public protocol SharedAppGroupDataManaging: Sendable {
    func loadSnapshot() async throws -> SharedAppGroupSnapshot
    func saveHistory(_ records: [TranscriptionRecord]) async throws
    func savePreferences(_ preferences: UserPreferences) throws
}

public actor JSONHistoryStore: HistoryStoring {
    private let configuration: AppGroupConfiguration
    private let resolver: SharedContainerResolving
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager
    private let maxRecordCount: Int

    public init(
        configuration: AppGroupConfiguration,
        resolver: SharedContainerResolving,
        fileManager: FileManager = .default,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        maxRecordCount: Int = 500
    ) {
        self.configuration = configuration
        self.resolver = resolver
        self.fileManager = fileManager
        self.encoder = encoder
        self.decoder = decoder
        self.maxRecordCount = maxRecordCount
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public func loadHistory() async throws -> [TranscriptionRecord] {
        let fileURL = try historyFileURL()
        guard fileManager.fileExists(atPath: fileURL.path()) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)

        if let envelope = try? decoder.decode(HistoryFileEnvelope.self, from: data) {
            return envelope.records
        }

        let legacyRecords = try decoder.decode([TranscriptionRecord].self, from: data)
        try persistHistory(legacyRecords)
        return legacyRecords
    }

    public func saveHistory(_ records: [TranscriptionRecord]) async throws {
        try persistHistory(records)
    }

    public func append(_ record: TranscriptionRecord) async throws {
        try await upsert(record)
    }

    public func upsert(_ record: TranscriptionRecord) async throws {
        var history = try await loadHistory()
        history.removeAll { $0.id == record.id }
        history.insert(record, at: 0)
        try persistHistory(history)
    }

    public func removeRecord(withID id: UUID) async throws {
        var history = try await loadHistory()
        history.removeAll { $0.id == id }
        try persistHistory(history)
    }

    public func removeAll() async throws {
        let fileURL = try historyFileURL()
        guard fileManager.fileExists(atPath: fileURL.path()) else {
            return
        }

        try fileManager.removeItem(at: fileURL)
    }

    private func persistHistory(_ records: [TranscriptionRecord]) throws {
        let trimmedRecords = Array(records.prefix(maxRecordCount))
        let data = try encoder.encode(HistoryFileEnvelope(records: trimmedRecords))
        try data.write(to: try historyFileURL(), options: .atomic)
    }

    private func historyFileURL() throws -> URL {
        let containerURL = try resolver.containerURL(for: configuration)
        if !fileManager.fileExists(atPath: containerURL.path()) {
            try fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true)
        }
        return containerURL.appending(path: configuration.historyFilename, directoryHint: .notDirectory)
    }
}

public struct UserDefaultsSettingsStore: SettingsStoring {
    private let configuration: AppGroupConfiguration
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        configuration: AppGroupConfiguration,
        userDefaults: UserDefaults? = nil,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.configuration = configuration
        self.userDefaults = userDefaults ?? UserDefaults(suiteName: configuration.identifier) ?? .standard
        self.encoder = encoder
        self.decoder = decoder
    }

    public func load() -> UserPreferences {
        guard let data = userDefaults.data(forKey: configuration.settingsKey) else {
            return UserPreferences(
                keyboard: KeyboardPreferences(appGroupIdentifier: configuration.identifier)
            )
        }

        if let envelope = try? decoder.decode(SettingsEnvelope.self, from: data) {
            return envelope.preferences
        }

        guard let preferences = try? decoder.decode(UserPreferences.self, from: data) else {
            return UserPreferences(
                keyboard: KeyboardPreferences(appGroupIdentifier: configuration.identifier)
            )
        }

        var migratedPreferences = preferences
        if migratedPreferences.keyboard.appGroupIdentifier == KeyboardPreferences.defaultValue.appGroupIdentifier {
            migratedPreferences.keyboard.appGroupIdentifier = configuration.identifier
        }

        try? save(migratedPreferences)
        return migratedPreferences
    }

    public func save(_ preferences: UserPreferences) throws {
        let data = try encoder.encode(SettingsEnvelope(preferences: preferences))
        userDefaults.set(data, forKey: configuration.settingsKey)
    }

    public func reset() throws {
        userDefaults.removeObject(forKey: configuration.settingsKey)
    }
}

public actor SharedAppGroupDataStore: SharedAppGroupDataManaging {
    private let historyStore: any HistoryStoring
    private let settingsStore: any SettingsStoring
    private let modelManifestStore: (any SpeechModelManifestStoring)?

    public init(
        historyStore: any HistoryStoring,
        settingsStore: any SettingsStoring,
        modelManifestStore: (any SpeechModelManifestStoring)? = nil
    ) {
        self.historyStore = historyStore
        self.settingsStore = settingsStore
        self.modelManifestStore = modelManifestStore
    }

    public func loadSnapshot() async throws -> SharedAppGroupSnapshot {
        async let history = historyStore.loadHistory()
        let preferences = settingsStore.load()

        let models: [SpeechModelDescriptor]
        if let modelManifestStore {
            models = try await modelManifestStore.loadManifest()
        } else {
            models = []
        }

        return SharedAppGroupSnapshot(
            history: try await history,
            preferences: preferences,
            models: models
        )
    }

    public func saveHistory(_ records: [TranscriptionRecord]) async throws {
        try await historyStore.saveHistory(records)
    }

    public func savePreferences(_ preferences: UserPreferences) throws {
        try settingsStore.save(preferences)
    }
}
