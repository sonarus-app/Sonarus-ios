import Foundation

public struct TranscriptionRequest: Hashable, Sendable {
    public var localeIdentifier: String
    public var taskHint: TaskHint
    public var preferredModelIdentifier: String?
    public var contextualStrings: [String]
    public var enablesPartialResults: Bool

    public init(
        localeIdentifier: String,
        taskHint: TaskHint = .dictation,
        preferredModelIdentifier: String? = nil,
        contextualStrings: [String] = [],
        enablesPartialResults: Bool = true
    ) {
        self.localeIdentifier = localeIdentifier
        self.taskHint = taskHint
        self.preferredModelIdentifier = preferredModelIdentifier
        self.contextualStrings = contextualStrings
        self.enablesPartialResults = enablesPartialResults
    }

    public enum TaskHint: String, Hashable, Sendable {
        case dictation
        case search
        case command
    }
}

public enum TranscriptionEvent: Sendable, Equatable {
    case preparing
    case listening
    case partial(TranscriptionSegment)
    case final(TranscriptionRecord)
    case failed(String)
}

public protocol TranscriptionEngine: Sendable {
    var kind: EngineKind { get }
    func start(request: TranscriptionRequest) -> AsyncThrowingStream<TranscriptionEvent, Error>
    func stop() async
}

public enum EngineKind: String, Codable, Sendable {
    case advancedOffline
    case speechRecognizerFallback
}

public protocol AudioFrameIngesting: Sendable {
    func ingestAudioFrame(_ bytes: Data, at timestamp: TimeInterval) async throws
}

public struct TranscriptionPipelinePlan: Hashable, Sendable {
    public var primaryEngine: EngineKind
    public var fallbackEngine: EngineKind?
    public var persistsHistory: Bool
    public var exposesKeyboardBridge: Bool

    public init(
        primaryEngine: EngineKind,
        fallbackEngine: EngineKind? = nil,
        persistsHistory: Bool = true,
        exposesKeyboardBridge: Bool = true
    ) {
        self.primaryEngine = primaryEngine
        self.fallbackEngine = fallbackEngine
        self.persistsHistory = persistsHistory
        self.exposesKeyboardBridge = exposesKeyboardBridge
    }
}

public protocol TextInsertionSink: Sendable {
    func insert(text: String)
    func deleteBackward()
}

public protocol KeyboardBridging: Sendable {
    func mostRecentTranscriptions(limit: Int) async throws -> [TranscriptionRecord]
    func settingsSnapshot() -> UserPreferences
}

public struct SharedKeyboardBridge: KeyboardBridging {
    private let historyStore: any HistoryStoring
    private let settingsStore: any SettingsStoring

    public init(historyStore: any HistoryStoring, settingsStore: any SettingsStoring) {
        self.historyStore = historyStore
        self.settingsStore = settingsStore
    }

    public func mostRecentTranscriptions(limit: Int) async throws -> [TranscriptionRecord] {
        Array(try await historyStore.loadHistory().prefix(limit))
    }

    public func settingsSnapshot() -> UserPreferences {
        settingsStore.load()
    }
}

public struct StubTranscriptionEngine: TranscriptionEngine {
    public let kind: EngineKind
    private let scriptedEvents: [TranscriptionEvent]

    public init(kind: EngineKind, scriptedEvents: [TranscriptionEvent] = [.preparing, .listening]) {
        self.kind = kind
        self.scriptedEvents = scriptedEvents
    }

    public func start(request: TranscriptionRequest) -> AsyncThrowingStream<TranscriptionEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                for event in scriptedEvents {
                    continuation.yield(event)
                }
                continuation.finish()
            }
        }
    }

    public func stop() async {}
}
