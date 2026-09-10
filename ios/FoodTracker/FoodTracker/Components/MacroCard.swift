import SwiftUI

struct MacroCard: View {
    let title: String
    let value: Double
    let unit: String
    let symbol: String
    var color: Color = .teal

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol).font(.subheadline).foregroundStyle(color)
            Text(value, format: .number.precision(.fractionLength(0...1)))
                .font(.system(.title, design: .rounded, weight: .bold)).contentTransition(.numericText())
            Text(unit).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding().background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}

struct MacroGrid: View {
    let summary: MacroSummary
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MacroCard(title: "Calories", value: summary.calories, unit: "kcal", symbol: "flame", color: .orange)
            MacroCard(title: "Protein", value: summary.protein, unit: "grams", symbol: "bolt", color: .teal)
            MacroCard(title: "Carbs", value: summary.carbs, unit: "grams", symbol: "leaf", color: .green)
            MacroCard(title: "Fat", value: summary.fat, unit: "grams", symbol: "drop", color: .purple)
        }
    }
}
