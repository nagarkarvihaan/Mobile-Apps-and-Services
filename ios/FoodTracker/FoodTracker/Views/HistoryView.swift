import SwiftUI

struct HistoryView: View {
    @Bindable var model: HomeViewModel

    private var grouped: [(date: Date, meals: [Meal])] {
        Dictionary(grouping: model.meals) { Calendar.current.startOfDay(for: $0.createdAt) }
            .map { (date: $0.key, meals: $0.value) }.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                if let error = model.errorMessage {
                    Section {
                        ErrorNotice(message: error)
                        Button("Try Again") { Task { await model.refresh() } }
                    }
                }
                if model.meals.isEmpty {
                    ContentUnavailableView("Your meals, at a glance", systemImage: "clock",
                                           description: Text("Saved meals will appear here."))
                }
                ForEach(grouped, id: \.date) { group in
                    Section {
                        ForEach(group.meals) { MealRow(meal: $0) }
                    } header: {
                        Text(group.date, format: .dateTime.month(.wide).day().year())
                    }
                }
            }
            .navigationTitle("History")
            .overlay { if model.isLoading && model.meals.isEmpty { ProgressView() } }
            .refreshable { await model.refresh() }
            .task { await model.refresh() }
        }
    }
}
