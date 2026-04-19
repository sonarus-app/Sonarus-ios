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
    public var tags: [String]
    public var isPinned: Bool

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        localeIdentifier: String,
        source: Source,
        text: String,
        duration: TimeInterval,
        segments: [TranscriptionSegment] = [],
        modelIdentifier: String? = nil,
        metadata: [String: String] = [:],
        tags: [String] = [],
        isPinned: Bool = false
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
        self.tags = tags
        self.isPinned = isPinned
    }

    public enum Source: String, Codable, Sendable {
        case hostApp
        case keyboardExtension
        case importedAudio
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case localeIdentifier
        case source
        case text
        case duration
        case segments
        case modelIdentifier
        case metadata
        case tags
        case isPinned
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.localeIdentifier = try container.decode(String.self, forKey: .localeIdentifier)
        self.source = try container.decode(Source.self, forKey: .source)
        self.text = try container.decode(String.self, forKey: .text)
        self.duration = try container.decode(TimeInterval.self, forKey: .duration)
        self.segments = try container.decodeIfPresent([TranscriptionSegment].self, forKey: .segments) ?? []
        self.modelIdentifier = try container.decodeIfPresent(String.self, forKey: .modelIdentifier)
        self.metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        self.isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(localeIdentifier, forKey: .localeIdentifier)
        try container.encode(source, forKey: .source)
        try container.encode(text, forKey: .text)
        try container.encode(duration, forKey: .duration)
        try container.encode(segments, forKey: .segments)
        try container.encodeIfPresent(modelIdentifier, forKey: .modelIdentifier)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(tags, forKey: .tags)
        try container.encode(isPinned, forKey: .isPinned)
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

public enum CaptureMode: String, Codable, CaseIterable, Sendable, Hashable {
    case keyboard
    case microphone
    case blended
}

public enum ThemePreference: String, Codable, CaseIterable, Sendable, Hashable {
    case system
    case light
    case dark
}

public enum KeyboardQuickAction: String, Codable, CaseIterable, Sendable, Hashable {
    case startDictation
    case pasteLatestTranscript
    case switchModel
    case openHistory
}

public struct KeyboardPreferences: Hashable, Codable, Sendable {
    public var appGroupIdentifier: String
    public var pasteboardBridgeEnabled: Bool
    public var openHostAppShortcutEnabled: Bool
    public var quickActions: [KeyboardQuickAction]

    public init(
        appGroupIdentifier: String,
        pasteboardBridgeEnabled: Bool = false,
        openHostAppShortcutEnabled: Bool = true,
        quickActions: [KeyboardQuickAction] = [.pasteLatestTranscript, .openHistory]
    ) {
        self.appGroupIdentifier = appGroupIdentifier
        self.pasteboardBridgeEnabled = pasteboardBridgeEnabled
        self.openHostAppShortcutEnabled = openHostAppShortcutEnabled
        self.quickActions = quickActions
    }

    enum CodingKeys: String, CodingKey {
        case appGroupIdentifier
        case pasteboardBridgeEnabled
        case openHostAppShortcutEnabled
        case quickActions
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.appGroupIdentifier = try container.decode(String.self, forKey: .appGroupIdentifier)
        self.pasteboardBridgeEnabled = try container.decodeIfPresent(Bool.self, forKey: .pasteboardBridgeEnabled) ?? false
        self.openHostAppShortcutEnabled = try container.decodeIfPresent(Bool.self, forKey: .openHostAppShortcutEnabled) ?? true
        self.quickActions = try container.decodeIfPresent([KeyboardQuickAction].self, forKey: .quickActions) ?? [.pasteLatestTranscript, .openHistory]
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(appGroupIdentifier, forKey: .appGroupIdentifier)
        try container.encode(pasteboardBridgeEnabled, forKey: .pasteboardBridgeEnabled)
        try container.encode(openHostAppShortcutEnabled, forKey: .openHostAppShortcutEnabled)
        try container.encode(quickActions, forKey: .quickActions)
    }
}

public struct UserPreferences: Hashable, Codable, Sendable {
    public var preferredLocaleIdentifier: String
    public var automaticallyCapitalize: Bool
    public var hapticsEnabled: Bool
    public var saveHistory: Bool
    public var keepScreenAwakeDuringRecording: Bool
    public var preferredModelIdentifier: String?
    public var autoCopyLatestTranscript: Bool
    public var automaticallyInsertAfterTranscription: Bool
    public var saveAudioClips: Bool
    public var keepTranscriptsOnDeviceOnly: Bool
    public var preferredCaptureMode: CaptureMode
    public var theme: ThemePreference
    public var keyboard: KeyboardPreferences

    public init(
        preferredLocaleIdentifier: String = Locale.current.identifier,
        automaticallyCapitalize: Bool = true,
        hapticsEnabled: Bool = true,
        saveHistory: Bool = true,
        keepScreenAwakeDuringRecording: Bool = true,
        preferredModelIdentifier: String? = nil,
        autoCopyLatestTranscript: Bool = true,
        automaticallyInsertAfterTranscription: Bool = true,
        saveAudioClips: Bool = false,
        keepTranscriptsOnDeviceOnly: Bool = true,
        preferredCaptureMode: CaptureMode = .keyboard,
        theme: ThemePreference = .system,
        keyboard: KeyboardPreferences = .defaultValue
    ) {
        self.preferredLocaleIdentifier = preferredLocaleIdentifier
        self.automaticallyCapitalize = automaticallyCapitalize
        self.hapticsEnabled = hapticsEnabled
        self.saveHistory = saveHistory
        self.keepScreenAwakeDuringRecording = keepScreenAwakeDuringRecording
        self.preferredModelIdentifier = preferredModelIdentifier
        self.autoCopyLatestTranscript = autoCopyLatestTranscript
        self.automaticallyInsertAfterTranscription = automaticallyInsertAfterTranscription
        self.saveAudioClips = saveAudioClips
        self.keepTranscriptsOnDeviceOnly = keepTranscriptsOnDeviceOnly
        self.preferredCaptureMode = preferredCaptureMode
        self.theme = theme
        self.keyboard = keyboard
    }

    enum CodingKeys: String, CodingKey {
        case preferredLocaleIdentifier
        case automaticallyCapitalize
        case hapticsEnabled
        case saveHistory
        case keepScreenAwakeDuringRecording
        case preferredModelIdentifier
        case autoCopyLatestTranscript
        case automaticallyInsertAfterTranscription
        case saveAudioClips
        case keepTranscriptsOnDeviceOnly
        case preferredCaptureMode
        case theme
        case keyboard
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.preferredLocaleIdentifier = try container.decodeIfPresent(String.self, forKey: .preferredLocaleIdentifier) ?? Locale.current.identifier
        self.automaticallyCapitalize = try container.decodeIfPresent(Bool.self, forKey: .automaticallyCapitalize) ?? true
        self.hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        self.saveHistory = try container.decodeIfPresent(Bool.self, forKey: .saveHistory) ?? true
        self.keepScreenAwakeDuringRecording = try container.decodeIfPresent(Bool.self, forKey: .keepScreenAwakeDuringRecording) ?? true
        self.preferredModelIdentifier = try container.decodeIfPresent(String.self, forKey: .preferredModelIdentifier)
        self.autoCopyLatestTranscript = try container.decodeIfPresent(Bool.self, forKey: .autoCopyLatestTranscript) ?? true
        self.automaticallyInsertAfterTranscription = try container.decodeIfPresent(Bool.self, forKey: .automaticallyInsertAfterTranscription) ?? true
        self.saveAudioClips = try container.decodeIfPresent(Bool.self, forKey: .saveAudioClips) ?? false
        self.keepTranscriptsOnDeviceOnly = try container.decodeIfPresent(Bool.self, forKey: .keepTranscriptsOnDeviceOnly) ?? true
        self.preferredCaptureMode = try container.decodeIfPresent(CaptureMode.self, forKey: .preferredCaptureMode) ?? .keyboard
        self.theme = try container.decodeIfPresent(ThemePreference.self, forKey: .theme) ?? .system
        self.keyboard = try container.decodeIfPresent(KeyboardPreferences.self, forKey: .keyboard) ?? .defaultValue
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(preferredLocaleIdentifier, forKey: .preferredLocaleIdentifier)
        try container.encode(automaticallyCapitalize, forKey: .automaticallyCapitalize)
        try container.encode(hapticsEnabled, forKey: .hapticsEnabled)
        try container.encode(saveHistory, forKey: .saveHistory)
        try container.encode(keepScreenAwakeDuringRecording, forKey: .keepScreenAwakeDuringRecording)
        try container.encodeIfPresent(preferredModelIdentifier, forKey: .preferredModelIdentifier)
        try container.encode(autoCopyLatestTranscript, forKey: .autoCopyLatestTranscript)
        try container.encode(automaticallyInsertAfterTranscription, forKey: .automaticallyInsertAfterTranscription)
        try container.encode(saveAudioClips, forKey: .saveAudioClips)
        try container.encode(keepTranscriptsOnDeviceOnly, forKey: .keepTranscriptsOnDeviceOnly)
        try container.encode(preferredCaptureMode, forKey: .preferredCaptureMode)
        try container.encode(theme, forKey: .theme)
        try container.encode(keyboard, forKey: .keyboard)
    }
}

public extension KeyboardPreferences {
    static let defaultValue = KeyboardPreferences(appGroupIdentifier: "group.com.sonarus.shared")
}
