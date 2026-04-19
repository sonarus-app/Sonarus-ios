import Foundation
import SwiftUI

enum AppTab: Hashable {
    case history
    case models
    case settings
}

enum CaptureMode: String, CaseIterable, Identifiable {
    case keyboard
    case microphone
    case blended

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keyboard:
            return "Keyboard-first"
        case .microphone:
            return "Microphone-first"
        case .blended:
            return "Blend both"
        }
    }
}

enum AppThemePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

enum KeyboardQuickAction: String, CaseIterable, Identifiable {
    case startDictation
    case pasteLatestTranscript
    case switchModel
    case openHistory

    var id: String { rawValue }

    var title: String {
        switch self {
        case .startDictation:
            return "Start or stop dictation"
        case .pasteLatestTranscript:
            return "Paste latest transcript"
        case .switchModel:
            return "Switch active model"
        case .openHistory:
            return "Open history"
        }
    }

    var subtitle: String {
        switch self {
        case .startDictation:
            return "Primary keyboard command for voice capture."
        case .pasteLatestTranscript:
            return "Insert the most recent saved transcript into the current field."
        case .switchModel:
            return "Cycle between installed models without opening settings."
        case .openHistory:
            return "Jump into the host app when a longer snippet needs review."
        }
    }
}

struct KeyboardExtensionSettings: Equatable {
    var appGroupIdentifier: String
    var pasteboardBridgeEnabled: Bool
    var openHostAppShortcutEnabled: Bool
    var quickActions: [KeyboardQuickAction]
}

struct UserSettings: Equatable {
    var autoCopyLatestTranscript: Bool
    var automaticallyInsertAfterTranscription: Bool
    var saveAudioClips: Bool
    var keepTranscriptsOnDeviceOnly: Bool
    var preferredCaptureMode: CaptureMode
    var theme: AppThemePreference
    var keyboard: KeyboardExtensionSettings

    static let sample = UserSettings(
        autoCopyLatestTranscript: true,
        automaticallyInsertAfterTranscription: true,
        saveAudioClips: false,
        keepTranscriptsOnDeviceOnly: true,
        preferredCaptureMode: .keyboard,
        theme: .system,
        keyboard: .init(
            appGroupIdentifier: "group.com.sonarus.shared",
            pasteboardBridgeEnabled: true,
            openHostAppShortcutEnabled: true,
            quickActions: [.startDictation, .pasteLatestTranscript]
        )
    )
}

enum ModelInstallState: Equatable {
    case installed
    case downloading(progress: Double)
    case notInstalled
    case updateAvailable

    var badgeTitle: String {
        switch self {
        case .installed:
            return "Installed"
        case .downloading:
            return "Downloading"
        case .notInstalled:
            return "Not installed"
        case .updateAvailable:
            return "Update"
        }
    }

    var tint: Color {
        switch self {
        case .installed:
            return .green
        case .downloading:
            return .orange
        case .notInstalled:
            return .secondary
        case .updateAvailable:
            return .yellow
        }
    }

    func primaryActionTitle(isActive: Bool) -> String {
        switch self {
        case .installed:
            return isActive ? "Current" : "Set Active"
        case .downloading:
            return "Finish"
        case .notInstalled:
            return "Install"
        case .updateAvailable:
            return "Update & Activate"
        }
    }

    var countsAsInstalled: Bool {
        switch self {
        case .installed, .updateAvailable:
            return true
        case .downloading, .notInstalled:
            return false
        }
    }
}

struct LocalSpeechModel: Identifiable, Equatable {
    let id: UUID
    var name: String
    var locale: String
    var sizeInMB: Int
    var latencyLabel: String
    var accuracyLabel: String
    var isRecommended: Bool
    var isActive: Bool
    var installState: ModelInstallState
    var lastUsedAt: Date?
}

enum CaptureSource: String, CaseIterable {
    case keyboard
    case microphone
    case shareExtension

    var label: String {
        switch self {
        case .keyboard:
            return "Keyboard"
        case .microphone:
            return "Mic"
        case .shareExtension:
            return "Share"
        }
    }

    var tint: Color {
        switch self {
        case .keyboard:
            return AppTheme.accent
        case .microphone:
            return .purple
        case .shareExtension:
            return .mint
        }
    }
}

struct TranscriptionRecord: Identifiable, Equatable {
    let id: UUID
    var createdAt: Date
    var duration: TimeInterval
    var text: String
    var source: CaptureSource
    var tags: [String]
    var isPinned: Bool
}

extension LocalSpeechModel {
    static var samples: [LocalSpeechModel] {
        [
            .init(
                id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
                name: "Whisper Small",
                locale: "English (US)",
                sizeInMB: 512,
                latencyLabel: "Fast",
                accuracyLabel: "Balanced",
                isRecommended: true,
                isActive: true,
                installState: .installed,
                lastUsedAt: .now.addingTimeInterval(-1_200)
            ),
            .init(
                id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
                name: "Whisper Medium",
                locale: "English (US)",
                sizeInMB: 1536,
                latencyLabel: "Moderate",
                accuracyLabel: "High",
                isRecommended: true,
                isActive: false,
                installState: .notInstalled,
                lastUsedAt: nil
            ),
            .init(
                id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
                name: "Whisper Multilingual",
                locale: "Spanish / English",
                sizeInMB: 768,
                latencyLabel: "Fast",
                accuracyLabel: "Balanced",
                isRecommended: false,
                isActive: false,
                installState: .updateAvailable,
                lastUsedAt: .now.addingTimeInterval(-86_400)
            )
        ]
    }
}

extension TranscriptionRecord {
    static var samples: [TranscriptionRecord] {
        [
            .init(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                createdAt: .now.addingTimeInterval(-900),
                duration: 42,
                text: "Draft the follow-up email and mention that the on-device model is already downloaded for the flight.",
                source: .keyboard,
                tags: ["Travel", "Follow up"],
                isPinned: true
            ),
            .init(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                createdAt: .now.addingTimeInterval(-3_200),
                duration: 18,
                text: "Pickup oat milk, green onions, and extra batteries for the microphone kit.",
                source: .microphone,
                tags: ["Errands"],
                isPinned: false
            ),
            .init(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                createdAt: .now.addingTimeInterval(-86_400),
                duration: 64,
                text: "Summarize the customer interview and highlight the request for a keyboard shortcut that opens full history.",
                source: .shareExtension,
                tags: ["Research", "Customer call"],
                isPinned: false
            )
        ]
    }
}
