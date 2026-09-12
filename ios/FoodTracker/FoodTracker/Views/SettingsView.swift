import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("Backend connection") {
                    Label("Azure cloud service", systemImage: "cloud")
                    Text("FoodTracker connects automatically. Your Mac does not need to be running.")
                        .foregroundStyle(.secondary)
                }
                Section("About your data") {
                    Text("This version uses a shared meal history. Meals are held temporarily and disappear when the server restarts.")
                    Text("Photos are sent to our server and Google Gemini for analysis. FoodTracker does not save your photos.")
                    Text("Nutrition values are AI estimates. Review portion sizes and edit the numbers before saving.")
                }
            }.navigationTitle("Settings")
        }
    }
}
