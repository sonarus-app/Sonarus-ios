import Foundation
import Testing
@testable import SonarusCore

private struct LegacyUserPreferencesV1: Codable {
    var preferredLocaleIdentifier: String
    var automaticallyCapitalize: Bool
    var hapticsEnabled: Bool
    var saveHistory: Bool
    var keepScreenAwakeDuringRecording: Bool
    var preferredModelIdentifier: String?
}

@Suite("UserDefaultsSettingsStore")
struct SettingsStoreTests {
    @Test("round trips user preferences through a dedicated suite using a versioned envelope")
    func roundTripPreferences() throws {
        let suiteName = "sonarus.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let configuration = AppGroupConfiguration(identifier: suiteName)
        let store = UserDefaultsSettingsStore(configuration: configuration, userDefaults: defaults)
        let preferences = UserPreferences(
            preferredLocaleIdentifier: "en_GB",
            automaticallyCapitalize: false,
            hapticsEnabled: false,
            saveHistory: true,
            keepScreenAwakeDuringRecording: false,
            preferredModelIdentifier: "offline.en-GB",
            autoCopyLatestTranscript: false,
            automaticallyInsertAfterTranscription: false,
            saveAudioClips: true,
            keepTranscriptsOnDeviceOnly: true,
            preferredCaptureMode: .microphone,
            theme: .dark,
            keyboard: KeyboardPreferences(
                appGroupIdentifier: suiteName,
                pasteboardBridgeEnabled: true,
                openHostAppShortcutEnabled: false,
                quickActions: [.switchModel, .openHistory]
            )
        )

        try store.save(preferences)
        let loaded = store.load()

        #expect(loaded == preferences)

        let envelopeData = try #require(defaults.data(forKey: configuration.settingsKey))
        let envelope = try JSONDecoder().decode(SettingsEnvelope.self, from: envelopeData)
        #expect(envelope.schemaVersion == AppGroupSchemaVersion.current)
        #expect(envelope.preferences == preferences)

        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test("load migrates legacy unversioned preferences and fills new defaults")
    func migratesLegacyPreferences() throws {
        let suiteName = "sonarus.legacy.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let configuration = AppGroupConfiguration(identifier: suiteName)
        let legacy = LegacyUserPreferencesV1(
            preferredLocaleIdentifier: "fr_FR",
            automaticallyCapitalize: false,
            hapticsEnabled: false,
            saveHistory: false,
            keepScreenAwakeDuringRecording: false,
            preferredModelIdentifier: "offline.fr"
        )
        defaults.set(try JSONEncoder().encode(legacy), forKey: configuration.settingsKey)

        let store = UserDefaultsSettingsStore(configuration: configuration, userDefaults: defaults)
        let loaded = store.load()

        #expect(loaded.preferredLocaleIdentifier == "fr_FR")
        #expect(loaded.preferredModelIdentifier == "offline.fr")
        #expect(loaded.autoCopyLatestTranscript)
        #expect(loaded.automaticallyInsertAfterTranscription)
        #expect(!loaded.saveAudioClips)
        #expect(loaded.keepTranscriptsOnDeviceOnly)
        #expect(loaded.preferredCaptureMode == .keyboard)
        #expect(loaded.theme == .system)
        #expect(loaded.keyboard.appGroupIdentifier == suiteName)

        let migratedData = try #require(defaults.data(forKey: configuration.settingsKey))
        let envelope = try JSONDecoder().decode(SettingsEnvelope.self, from: migratedData)
        #expect(envelope.schemaVersion == AppGroupSchemaVersion.current)
        #expect(envelope.preferences.preferredLocaleIdentifier == "fr_FR")
        #expect(envelope.preferences.keyboard.appGroupIdentifier == suiteName)

        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test("reset removes the stored payload and falls back to configuration defaults")
    func reset() throws {
        let suiteName = "sonarus.reset.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let configuration = AppGroupConfiguration(identifier: suiteName)
        let store = UserDefaultsSettingsStore(configuration: configuration, userDefaults: defaults)

        try store.save(UserPreferences(preferredLocaleIdentifier: "en_AU", keyboard: KeyboardPreferences(appGroupIdentifier: suiteName)))
        try store.reset()

        let loaded = store.load()
        #expect(loaded.keyboard.appGroupIdentifier == suiteName)
        #expect(loaded.preferredLocaleIdentifier == Locale.current.identifier)

        defaults.removePersistentDomain(forName: suiteName)
    }
}
