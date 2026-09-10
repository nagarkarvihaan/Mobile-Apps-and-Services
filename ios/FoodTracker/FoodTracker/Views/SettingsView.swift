import SwiftUI

struct SettingsView: View {
    @AppStorage("backendURL") private var backendURL = ""
    @State private var editedURL = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://your-service.onrender.com", text: $editedURL)
                        .keyboardType(.URL).textContentType(.URL)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .accessibilityLabel("Backend URL")
                    Button("Connect") {
                        backendURL = editedURL.trimmingCharacters(in: .whitespacesAndNewlines)
                    }.disabled(APIService.configuredURL(editedURL) == nil || editedURL == backendURL)
                    if !backendURL.isEmpty {
                        Label("Server address saved", systemImage: "checkmark.circle").foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Backend connection")
                } footer: {
                    Text("Enter the HTTPS address of your FoodTracker service.")
                }
                Section("About your data") {
                    Text("This version uses a shared meal history. Meals are held temporarily and disappear when the server restarts.")
                    Text("Photos are sent to our server and Google Gemini for analysis. FoodTracker does not save your photos.")
                    Text("Nutrition values are AI estimates. Review portion sizes and edit the numbers before saving.")
                }
            }.navigationTitle("Settings").onAppear { editedURL = backendURL }
        }
    }
}
