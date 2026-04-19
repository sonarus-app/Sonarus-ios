import SwiftUI

@main
struct SonarusApp: App {
    @StateObject private var appState = AppState.preview

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appState)
        }
    }
}
