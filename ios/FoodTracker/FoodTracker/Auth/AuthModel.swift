import Foundation
import Observation

// Public project credentials only. Never put a service-role or secret key here.
enum SupabaseConfig {
    static let projectURL = "https://occtpttbvixhsvtfhkmq.supabase.co"
    static let publishableKey = "sb_publishable_35t45yQE8GD0OHFPiVg3RQ_b9fIyfrV"
}

@MainActor @Observable
final class AuthModel {
    private(set) var email: String?
    private(set) var accessToken: String?
    private(set) var isLoading = false
    var errorMessage: String?
    var notice: String?
    private var expiresAt: Date?

    var isSignedIn: Bool { accessToken != nil }

    func submit(email: String, password: String, createAccount: Bool) async {
        guard !isLoading else { return }
        errorMessage = nil
        notice = nil
        guard !SupabaseConfig.publishableKey.isEmpty,
              let baseURL = URL(string: SupabaseConfig.projectURL), baseURL.scheme == "https" else {
            errorMessage = "Login is unavailable because the app configuration is invalid."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            var components = URLComponents(url: baseURL.appendingPathComponent(
                createAccount ? "auth/v1/signup" : "auth/v1/token"
            ), resolvingAgainstBaseURL: false)!
            if !createAccount { components.queryItems = [URLQueryItem(name: "grant_type", value: "password")] }
            var request = URLRequest(url: components.url!)
            request.httpMethod = "POST"
            request.timeoutInterval = 30
            request.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode([
                "email": email.trimmingCharacters(in: .whitespacesAndNewlines), "password": password
            ])
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            guard (200..<300).contains(response.statusCode) else {
                struct Failure: Decodable {
                    let msg: String?
                    let message: String?
                    let error_description: String?
                }
                let failure = try? JSONDecoder().decode(Failure.self, from: data)
                throw APIError.server(failure?.msg ?? failure?.message ?? failure?.error_description
                    ?? "Unable to sign in. Please try again.")
            }
            struct Response: Decodable {
                struct User: Decodable { let email: String? }
                let access_token: String?
                let expires_in: Double?
                let user: User?
            }
            let result = try JSONDecoder().decode(Response.self, from: data)
            if let token = result.access_token, !token.isEmpty, let lifetime = result.expires_in {
                self.email = result.user?.email ?? email
                accessToken = token
                expiresAt = Date().addingTimeInterval(lifetime)
            } else if createAccount {
                notice = "Check your email to confirm your account, then come back and log in."
            } else {
                throw APIError.invalidResponse
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // This basic flow keeps the session only in memory and requires login again on expiry.
    func checkSession() {
        if let expiresAt, expiresAt <= Date() {
            signOut()
            notice = "Your session expired. Please log in again."
        }
    }

    func signOut() {
        accessToken = nil
        email = nil
        expiresAt = nil
        errorMessage = nil
        notice = nil
    }
}
