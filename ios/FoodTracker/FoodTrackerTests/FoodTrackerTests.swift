import XCTest
@testable import FoodTracker

private let sampleDraft = MealDraft(name: "Lunch", calories: 550, protein: 45, carbs: 60, fat: 14)

private func meal(at date: Date = .now) -> Meal {
    Meal(id: UUID(), name: "Lunch", calories: 550, protein: 45, carbs: 60, fat: 14, createdAt: date)
}

private actor StubAPI: MealAPI {
    var meals: [Meal]
    var shouldFail = false
    var saveIDs: [UUID] = []
    var savedDrafts: [MealDraft] = []

    init(meals: [Meal] = []) { self.meals = meals }
    func setFailure(_ value: Bool) { shouldFail = value }
    func fetchMeals() async throws -> [Meal] {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return meals
    }
    func analyze(image: Data) async throws -> MealDraft {
        if shouldFail { throw APIError.server("No food was found.") }
        return sampleDraft
    }
    func save(_ draft: MealDraft, requestID: UUID) async throws -> Meal {
        saveIDs.append(requestID)
        savedDrafts.append(draft)
        if shouldFail { throw URLError(.timedOut) }
        return meal()
    }
}

private actor SuspendedAPI: MealAPI {
    private var continuation: CheckedContinuation<[Meal], Never>?
    func fetchMeals() async throws -> [Meal] {
        await withCheckedContinuation { continuation = $0 }
    }
    func completeFetch() async {
        while continuation == nil { await Task.yield() }
        continuation?.resume(returning: [])
        continuation = nil
    }
    func analyze(image: Data) async throws -> MealDraft { sampleDraft }
    func save(_ draft: MealDraft, requestID: UUID) async throws -> Meal { meal() }
}

@MainActor
final class FoodTrackerTests: XCTestCase {
    func testTodayUsesLocalCalendarAndExcludesOtherDays() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: -4 * 3600)!
        let decoder = ISO8601DateFormatter()
        let today = decoder.date(from: "2026-09-10T12:00:00Z")!
        let lastNight = meal(at: decoder.date(from: "2026-09-10T02:00:00Z")!)
        let lunch = meal(at: today)
        let model = HomeViewModel()
        model.record(lastNight)
        model.record(lunch)
        XCTAssertEqual(model.meals(on: today, calendar: calendar), [lunch])
        XCTAssertEqual(MacroSummary(meals: [lunch, lastNight]).calories, 1100)
        XCTAssertEqual(MacroSummary(meals: []).protein, 0)
    }

    func testDraftValidationRejectsNonfiniteAndOutOfRangeValues() {
        XCTAssertTrue(sampleDraft.isValid)
        var draft = sampleDraft
        draft.calories = .nan
        XCTAssertFalse(draft.isValid)
        draft = sampleDraft
        draft.protein = -1
        XCTAssertFalse(draft.isValid)
        draft = sampleDraft
        draft.name = "  "
        XCTAssertFalse(draft.isValid)
    }

    func testRefreshFailureKeepsExistingMealsAndAllowsRetry() async {
        let lunch = meal()
        let api = StubAPI(meals: [lunch])
        let model = HomeViewModel(api: api)
        await model.refresh()
        XCTAssertEqual(model.meals, [lunch])
        await api.setFailure(true)
        await model.refresh()
        XCTAssertEqual(model.meals, [lunch])
        XCTAssertNotNil(model.errorMessage)
        XCTAssertFalse(model.isLoading)
        await api.setFailure(false)
        await model.refresh()
        XCTAssertNil(model.errorMessage)
    }

    func testRecordDoesNotDuplicateMeals() {
        let model = HomeViewModel()
        let lunch = meal()
        model.record(lunch)
        model.record(lunch)
        XCTAssertEqual(model.meals.count, 1)
    }

    func testRefreshStartedBeforeSaveCannotOverwriteSavedMeal() async {
        let api = SuspendedAPI()
        let model = HomeViewModel(api: api)
        let refresh = Task { await model.refresh() }
        while !model.isLoading { await Task.yield() }
        let saved = meal()
        model.record(saved)
        await api.completeFetch()
        await refresh.value
        XCTAssertEqual(model.meals, [saved])
        XCTAssertFalse(model.isLoading)
    }

    func testAnalysisFailureAndRetry() async {
        let api = StubAPI()
        let model = MealViewModel(api: api)
        model.imageData = Data([1, 2])
        await api.setFailure(true)
        await model.analyze()
        XCTAssertNil(model.draft)
        XCTAssertFalse(model.isAnalyzing)
        XCTAssertNotNil(model.errorMessage)
        await api.setFailure(false)
        await model.analyze()
        XCTAssertEqual(model.draft, sampleDraft)
        XCTAssertNil(model.errorMessage)
    }

    func testSaveRetryReusesIDAndOriginalPayloadAfterTimeout() async {
        let api = StubAPI()
        let model = MealViewModel(api: api)
        await api.setFailure(true)
        let failed = await model.save(sampleDraft)
        XCTAssertNil(failed)
        XCTAssertTrue(model.hasPendingSave)
        await api.setFailure(false)
        var changed = sampleDraft
        changed.calories = 600
        let saved = await model.save(changed)
        XCTAssertNotNil(saved)
        let ids = await api.saveIDs
        let drafts = await api.savedDrafts
        XCTAssertEqual(ids.count, 2)
        XCTAssertEqual(ids[0], ids[1])
        XCTAssertEqual(drafts, [sampleDraft, sampleDraft])
    }

    func testProductionBackendUsesAzureHTTPSOrigin() {
        XCTAssertEqual(APIService.productionBaseURL.scheme, "https")
        XCTAssertEqual(
            APIService.productionBaseURL.host,
            "foodtracker-api-gmcnbzepc4a4f4h5.canadacentral-01.azurewebsites.net"
        )
        XCTAssertEqual(APIService.productionBaseURL.path, "")
    }

    func testBackendJSONContractAndMultipartUpload() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let api = APIService(baseURL: URL(string: "https://example.com")!, session: session)
        StubURLProtocol.response = Data("""
        {"meals":[{"id":"A0000000-0000-0000-0000-000000000001","name":"Lunch","calories":550,"protein":45,"carbs":60,"fat":14,"created_at":"2026-09-10T16:00:00Z"}]}
        """.utf8)
        let meals = try await api.fetchMeals()
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals[0].calories, 550)
        XCTAssertEqual(StubURLProtocol.lastRequest?.url?.path, "/api/meals")
        StubURLProtocol.response = try JSONEncoder().encode(sampleDraft)
        let result = try await api.analyze(image: Data([0xFF, 0xD8]))
        XCTAssertEqual(result, sampleDraft)
        XCTAssertEqual(StubURLProtocol.lastRequest?.httpMethod, "POST")
        XCTAssertTrue(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data; boundary=") == true)
    }

    func testAPIReportsServerErrorsAndMalformedResponses() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let api = APIService(baseURL: URL(string: "https://example.com")!, session: URLSession(configuration: configuration))
        StubURLProtocol.status = 429
        StubURLProtocol.response = Data(#"{"error":{"message":"Wait a minute"}}"#.utf8)
        do {
            _ = try await api.fetchMeals()
            XCTFail("Expected an error")
        } catch { XCTAssertEqual(error.localizedDescription, "Wait a minute") }
        StubURLProtocol.status = 200
        StubURLProtocol.response = Data("not json".utf8)
        do {
            _ = try await api.fetchMeals()
            XCTFail("Expected a decoding error")
        } catch { XCTAssertEqual(error.localizedDescription, APIError.invalidResponse.localizedDescription) }
    }

    override func tearDown() {
        StubURLProtocol.status = 200
        StubURLProtocol.lastRequest = nil
    }
}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    // Tests run serially; URLSession invokes these on its own callback queue.
    nonisolated(unsafe) static var response = Data()
    nonisolated(unsafe) static var status = 200
    nonisolated(unsafe) static var lastRequest: URLRequest?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lastRequest = request
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.response)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
