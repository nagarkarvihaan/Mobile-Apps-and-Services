import SwiftUI

@main
struct FoodTrackerApp: App {
    @State private var auth = AuthModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isSignedIn {
                    SignedInView(auth: auth)
                } else {
                    LoginView(auth: auth)
                }
            }.tint(.teal)
        }
    }
}

private struct SignedInView: View {
    let auth: AuthModel
    @State private var home = HomeViewModel()
    @Environment(\.scenePhase) private var scenePhase

    init(auth: AuthModel) {
        self.auth = auth
        _home = State(initialValue: HomeViewModel(api: APIService(
            baseURL: APIService.productionBaseURL, accessToken: auth.accessToken
        )))
    }

    var body: some View {
        TabView {
            HomeView(model: home).tabItem { Label("Today", systemImage: "sun.max") }
            HistoryView(model: home).tabItem { Label("History", systemImage: "clock") }
            SettingsView(auth: auth).tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(.teal)
        .task { await home.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                auth.checkSession()
                if auth.isSignedIn { Task { await home.refresh() } }
            }
        }
    }
}
