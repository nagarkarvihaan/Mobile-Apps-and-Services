import SwiftUI

struct MealRow: View {
    let meal: Meal
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "fork.knife").font(.title3).foregroundStyle(.teal)
                .frame(width: 44, height: 44).background(.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 5) {
                Text(meal.name).font(.headline)
                Text(meal.createdAt, style: .time).font(.caption).foregroundStyle(.secondary)
                Text("P \(meal.protein, specifier: "%.1f")g · C \(meal.carbs, specifier: "%.1f")g · F \(meal.fat, specifier: "%.1f")g")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing) {
                Text(meal.calories, format: .number.precision(.fractionLength(0...1))).font(.headline)
                Text("kcal").font(.caption).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 6).accessibilityElement(children: .combine)
    }
}

struct ErrorNotice: View {
    let message: String
    var body: some View {
        Label(message, systemImage: "exclamationmark.circle")
            .font(.callout).foregroundStyle(.red).accessibilityLabel("Error: \(message)")
    }
}
