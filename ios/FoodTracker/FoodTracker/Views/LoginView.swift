import SwiftUI

struct LoginView: View {
    @Bindable var auth: AuthModel
    @State private var email = ""
    @State private var password = ""
    @State private var createAccount = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 48)).foregroundStyle(.teal)
                        Text("Welcome to FoodTracker").font(.title2.bold())
                        Text(createAccount ? "Create an account to get started." : "Log in to get started.")
                            .foregroundStyle(.secondary)
                    }.padding(.vertical)
                }
                Section {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                        .textContentType(createAccount ? .newPassword : .password)
                }
                if let error = auth.errorMessage {
                    Section { Text(error).foregroundStyle(.red).accessibilityLabel("Error: \(error)") }
                }
                if let notice = auth.notice {
                    Section { Text(notice).foregroundStyle(.secondary) }
                }
                Section {
                    Button {
                        Task {
                            await auth.submit(email: email, password: password, createAccount: createAccount)
                            if auth.isSignedIn || auth.notice != nil { password = "" }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if auth.isLoading { ProgressView() }
                            Text(createAccount ? "Create Account" : "Log In").bold()
                            Spacer()
                        }
                    }
                    .disabled(auth.isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
                    Button(createAccount ? "Already have an account? Log in" : "New here? Create an account") {
                        createAccount.toggle()
                        password = ""
                        auth.errorMessage = nil
                        auth.notice = nil
                    }.disabled(auth.isLoading)
                }
            }
            .disabled(auth.isLoading)
            .navigationTitle(createAccount ? "Create Account" : "Log In")
        }
    }
}
