import Foundation
import Testing
@testable import SonarusCore

@Suite("UserDefaultsSettingsStore")
struct SettingsStoreTests {
    @Test("round trips user preferences through a dedicated suite")
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
            preferredModelIdentifier: "offline.en-GB"
        )

        try store.save(preferences)
        let loaded = store.load()

        #expect(loaded == preferences)
        defaults.removePersistentDomain(forName: suiteName)
    }
}
