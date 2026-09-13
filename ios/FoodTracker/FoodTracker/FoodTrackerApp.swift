import SwiftUI

@main
struct FoodTrackerApp: App {
    @State private var home = HomeViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView(model: home).tabItem { Label("Today", systemImage: "sun.max") }
                HistoryView(model: home).tabItem { Label("History", systemImage: "clock") }
                SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }
            }
            .tint(.teal)
            .task { await home.refresh() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await home.refresh() } }
            }
        }
    }
}
