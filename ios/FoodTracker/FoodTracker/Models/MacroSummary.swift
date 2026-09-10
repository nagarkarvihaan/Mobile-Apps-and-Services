import Foundation

struct MacroSummary {
    var calories = 0.0
    var protein = 0.0
    var carbs = 0.0
    var fat = 0.0

    init(meals: [Meal]) {
        for meal in meals {
            calories += meal.calories
            protein += meal.protein
            carbs += meal.carbs
            fat += meal.fat
        }
    }
}
