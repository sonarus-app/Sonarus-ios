import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "text.page")
            }
            .tag(AppTab.history)

            NavigationStack {
                ModelManagementView()
            }
            .tabItem {
                Label("Models", systemImage: "square.stack.3d.up")
            }
            .tag(AppTab.models)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "slider.horizontal.3")
            }
            .tag(AppTab.settings)
        }
        .tint(AppTheme.accent)
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppState.preview)
}
