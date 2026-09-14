import Foundation

protocol MealAPI: Sendable {
    func fetchMeals() async throws -> [Meal]
    func analyze(image: Data) async throws -> MealDraft
    func save(_ draft: MealDraft, requestID: UUID) async throws -> Meal
}

enum APIError: LocalizedError {
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "The server returned an unreadable response. Please try again."
        case .server(let message): message
        }
    }
}

struct APIService: MealAPI {
    static let productionBaseURL = URL(
        string: "https://foodtracker-api-gmcnbzepc4a4f4h5.canadacentral-01.azurewebsites.net"
    )!
    static let production = APIService(baseURL: productionBaseURL)

    private struct ErrorEnvelope: Decodable {
        struct Detail: Decodable { let message: String }
        let error: Detail
    }

    let baseURL: URL
    private let session: URLSession
    private let accessToken: String?

    init(baseURL: URL, session: URLSession = .shared, accessToken: String? = nil) {
        self.baseURL = baseURL
        self.session = session
        self.accessToken = accessToken
    }

    func fetchMeals() async throws -> [Meal] {
        struct Envelope: Decodable { let meals: [Meal] }
        let result: Envelope = try await send(request(path: "api/meals"))
        return result.meals
    }

    func analyze(image: Data) async throws -> MealDraft {
        let boundary = UUID().uuidString
        var body = Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"image\"; filename=\"meal.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n".utf8)
        body.append(image)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        var request = request(path: "api/analyze-meal", method: "POST")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return try await send(request)
    }

    func save(_ draft: MealDraft, requestID: UUID) async throws -> Meal {
        var request = request(path: "api/meals", method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(requestID.uuidString, forHTTPHeaderField: "Idempotency-Key")
        request.httpBody = try JSONEncoder().encode(draft)
        return try await send(request)
    }

    private func request(path: String, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.timeoutInterval = 75
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let accessToken { request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization") }
        return request
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard (200..<300).contains(response.statusCode) else {
            let message = (try? decoder.decode(ErrorEnvelope.self, from: data))?.error.message
            throw APIError.server(message ?? "The server is unavailable (\(response.statusCode)). Please try again.")
        }
        do { return try decoder.decode(T.self, from: data) }
        catch { throw APIError.invalidResponse }
    }
}
