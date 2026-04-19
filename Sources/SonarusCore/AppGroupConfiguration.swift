import Foundation

public struct AppGroupConfiguration: Sendable, Hashable, Codable {
    public static let defaultHistoryFilename = "history.json"
    public static let defaultSettingsKey = "sonarus.settings"
    public static let defaultModelManifestFilename = "models.json"

    public let identifier: String
    public let historyFilename: String
    public let settingsKey: String
    public let modelManifestFilename: String

    public init(
        identifier: String,
        historyFilename: String = Self.defaultHistoryFilename,
        settingsKey: String = Self.defaultSettingsKey,
        modelManifestFilename: String = Self.defaultModelManifestFilename
    ) {
        self.identifier = identifier
        self.historyFilename = historyFilename
        self.settingsKey = settingsKey
        self.modelManifestFilename = modelManifestFilename
    }
}

public protocol SharedContainerResolving: Sendable {
    func containerURL(for configuration: AppGroupConfiguration) throws -> URL
}

public enum SharedContainerError: Error, LocalizedError, Equatable {
    case missingContainer(String)

    public var errorDescription: String? {
        switch self {
        case let .missingContainer(identifier):
            return "Unable to resolve shared container for app group \(identifier)."
        }
    }
}

public struct FileManagerAppGroupResolver: SharedContainerResolving {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func containerURL(for configuration: AppGroupConfiguration) throws -> URL {
        guard let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: configuration.identifier) else {
            throw SharedContainerError.missingContainer(configuration.identifier)
        }

        return url
    }
}

public struct StaticContainerResolver: SharedContainerResolving {
    private let rootURL: URL

    public init(rootURL: URL) {
        self.rootURL = rootURL
    }

    public func containerURL(for configuration: AppGroupConfiguration) throws -> URL {
        rootURL
    }
}
