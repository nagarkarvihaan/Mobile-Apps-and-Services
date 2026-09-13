import SwiftUI

struct HomeView: View {
    @Bindable var model: HomeViewModel
    @State private var showingAddMeal = false

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                let meals = model.meals(on: context.date)
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(context.date, format: .dateTime.weekday(.wide).month(.wide).day())
                                .font(.subheadline).foregroundStyle(.secondary)
                            Text("A little more mindful.").font(.title2.bold())
                        }
                        MacroGrid(summary: MacroSummary(meals: meals))
                        Button { showingAddMeal = true } label: {
                            Label("Add Meal", systemImage: "plus.circle.fill")
                                .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        if let error = model.errorMessage {
                            ErrorNotice(message: error)
                            Button("Try Again") { Task { await model.refresh() } }
                        }
                        HStack {
                            Text("Today's meals").font(.title3.bold())
                            Spacer()
                            if model.isLoading { ProgressView() }
                        }
                        if meals.isEmpty && !model.isLoading {
                            ContentUnavailableView("Start with your next meal", systemImage: "fork.knife.circle",
                                                   description: Text("Take a photo, review the estimate, and save your meal."))
                        } else {
                            ForEach(meals) { meal in
                                MealRow(meal: meal)
                                Divider()
                            }
                        }
                    }.padding()
                }
                .refreshable { await model.refresh() }
            }
            .navigationTitle("Today")
            .sheet(isPresented: $showingAddMeal, onDismiss: { Task { await model.refresh() } }) {
                AddMealView(api: model.api, onSave: model.record)
            }
        }
    }
}
