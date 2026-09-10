import Foundation
import Observation

@MainActor @Observable
final class HomeViewModel {
    private(set) var meals: [Meal] = []
    private(set) var isLoading = false
    var errorMessage: String?
    private(set) var api: (any MealAPI)?
    private var generation = 0

    init(api: (any MealAPI)? = nil) { self.api = api }

    func configure(url: String) {
        generation += 1
        api = APIService.configuredURL(url).map { APIService(baseURL: $0) }
        meals = []
        errorMessage = nil
        isLoading = false
    }

    func meals(on date: Date, calendar: Calendar = .current) -> [Meal] {
        meals.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }
    }

    func refresh() async {
        guard !isLoading else { return }
        guard let api else { errorMessage = APIError.configuration.localizedDescription; return }
        let currentGeneration = generation
        isLoading = true
        errorMessage = nil
        defer { if currentGeneration == generation { isLoading = false } }
        do {
            let result = try await api.fetchMeals()
            guard currentGeneration == generation, !Task.isCancelled else { return }
            meals = result.sorted { $0.createdAt > $1.createdAt }
        } catch {
            guard currentGeneration == generation, !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    func record(_ meal: Meal) {
        // A list request started before this save must not overwrite the saved meal.
        generation += 1
        isLoading = false
        meals.removeAll { $0.id == meal.id }
        meals.append(meal)
        meals.sort { $0.createdAt > $1.createdAt }
    }
}
