import Foundation

public struct TranscriptionSegment: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let text: String
    public let startTime: TimeInterval
    public let duration: TimeInterval
    public let isFinal: Bool

    public init(
        id: UUID = UUID(),
        text: String,
        startTime: TimeInterval,
        duration: TimeInterval,
        isFinal: Bool
    ) {
        self.id = id
        self.text = text
        self.startTime = startTime
        self.duration = duration
        self.isFinal = isFinal
    }
}

public struct TranscriptionRecord: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let createdAt: Date
    public var localeIdentifier: String
    public var source: Source
    public var text: String
    public var duration: TimeInterval
    public var segments: [TranscriptionSegment]
    public var modelIdentifier: String?
    public var metadata: [String: String]

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        localeIdentifier: String,
        source: Source,
        text: String,
        duration: TimeInterval,
        segments: [TranscriptionSegment] = [],
        modelIdentifier: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.localeIdentifier = localeIdentifier
        self.source = source
        self.text = text
        self.duration = duration
        self.segments = segments
        self.modelIdentifier = modelIdentifier
        self.metadata = metadata
    }

    public enum Source: String, Codable, Sendable {
        case hostApp
        case keyboardExtension
        case importedAudio
    }
}

public struct SpeechModelDescriptor: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public var displayName: String
    public var localeIdentifier: String
    public var storageRequirementBytes: Int64
    public var availability: Availability
    public var lastUpdatedAt: Date?

    public init(
        id: String,
        displayName: String,
        localeIdentifier: String,
        storageRequirementBytes: Int64,
        availability: Availability,
        lastUpdatedAt: Date? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.localeIdentifier = localeIdentifier
        self.storageRequirementBytes = storageRequirementBytes
        self.availability = availability
        self.lastUpdatedAt = lastUpdatedAt
    }

    public enum Availability: String, Codable, Sendable {
        case notInstalled
        case downloading
        case installed
        case unavailable
    }
}

public struct UserPreferences: Hashable, Codable, Sendable {
    public var preferredLocaleIdentifier: String
    public var automaticallyCapitalize: Bool
    public var hapticsEnabled: Bool
    public var saveHistory: Bool
    public var keepScreenAwakeDuringRecording: Bool
    public var preferredModelIdentifier: String?

    public init(
        preferredLocaleIdentifier: String = Locale.current.identifier,
        automaticallyCapitalize: Bool = true,
        hapticsEnabled: Bool = true,
        saveHistory: Bool = true,
        keepScreenAwakeDuringRecording: Bool = true,
        preferredModelIdentifier: String? = nil
    ) {
        self.preferredLocaleIdentifier = preferredLocaleIdentifier
        self.automaticallyCapitalize = automaticallyCapitalize
        self.hapticsEnabled = hapticsEnabled
        self.saveHistory = saveHistory
        self.keepScreenAwakeDuringRecording = keepScreenAwakeDuringRecording
        self.preferredModelIdentifier = preferredModelIdentifier
    }
}
