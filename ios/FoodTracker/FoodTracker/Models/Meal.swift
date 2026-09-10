import Foundation

struct MealDraft: Codable, Equatable, Sendable {
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double

    var isValid: Bool {
        let count = name.trimmingCharacters(in: .whitespacesAndNewlines).count
        return (1...120).contains(count)
            && calories.isFinite && (0...10000).contains(calories)
            && [protein, carbs, fat].allSatisfy { $0.isFinite && (0...1000).contains($0) }
    }
}

struct Meal: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, calories, protein, carbs, fat
        case createdAt = "created_at"
    }
}
