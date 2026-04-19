import Foundation

public protocol HistoryStoring: Sendable {
    func loadHistory() async throws -> [TranscriptionRecord]
    func append(_ record: TranscriptionRecord) async throws
    func removeAll() async throws
}

public protocol SettingsStoring: Sendable {
    func load() -> UserPreferences
    func save(_ preferences: UserPreferences) throws
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
        return try decoder.decode([TranscriptionRecord].self, from: data)
    }

    public func append(_ record: TranscriptionRecord) async throws {
        var history = try await loadHistory()
        history.insert(record, at: 0)
        if history.count > maxRecordCount {
            history = Array(history.prefix(maxRecordCount))
        }
        let data = try encoder.encode(history)
        try data.write(to: try historyFileURL(), options: .atomic)
    }

    public func removeAll() async throws {
        let fileURL = try historyFileURL()
        guard fileManager.fileExists(atPath: fileURL.path()) else {
            return
        }

        try fileManager.removeItem(at: fileURL)
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
            return UserPreferences()
        }

        return (try? decoder.decode(UserPreferences.self, from: data)) ?? UserPreferences()
    }

    public func save(_ preferences: UserPreferences) throws {
        let data = try encoder.encode(preferences)
        userDefaults.set(data, forKey: configuration.settingsKey)
    }
}
