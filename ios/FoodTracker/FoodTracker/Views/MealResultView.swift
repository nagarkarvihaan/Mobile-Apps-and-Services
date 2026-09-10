import SwiftUI

struct MealResultView: View {
    @Bindable var model: MealViewModel
    @State private var name: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @FocusState private var editing: Bool
    let onClose: () -> Void
    let onSave: (Meal) -> Void

    init(model: MealViewModel, draft: MealDraft, onClose: @escaping () -> Void, onSave: @escaping (Meal) -> Void) {
        self.model = model
        self.onClose = onClose
        self.onSave = onSave
        _name = State(initialValue: draft.name)
        let style = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...1)).grouping(.never)
        _calories = State(initialValue: draft.calories.formatted(style))
        _protein = State(initialValue: draft.protein.formatted(style))
        _carbs = State(initialValue: draft.carbs.formatted(style))
        _fat = State(initialValue: draft.fat.formatted(style))
    }

    private var editedDraft: MealDraft? {
        let style = FloatingPointFormatStyle<Double>.number.grouping(.never)
        guard let calories = try? Double(calories, format: style, lenient: false),
              let protein = try? Double(protein, format: style, lenient: false),
              let carbs = try? Double(carbs, format: style, lenient: false),
              let fat = try? Double(fat, format: style, lenient: false) else { return nil }
        let draft = MealDraft(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                              calories: calories, protein: protein, carbs: carbs, fat: fat)
        return draft.isValid ? draft : nil
    }

    var body: some View {
        Form {
            Section {
                Label("AI estimate", systemImage: "sparkles").foregroundStyle(.teal)
                Text("Portion sizes and ingredients can be hard to judge from a photo. Review and adjust your meal below.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            Section("Meal") { TextField("Meal name", text: $name).focused($editing) }
                .disabled(model.hasPendingSave)
            Section("Nutrition") {
                numberField("Calories (kcal)", value: $calories)
                numberField("Protein (g)", value: $protein)
                numberField("Carbs (g)", value: $carbs)
                numberField("Fat (g)", value: $fat)
            }.disabled(model.hasPendingSave)
            if editedDraft == nil {
                Text("Enter a name (1–120 characters), calories from 0–10,000, and each macro from 0–1,000 grams.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if let error = model.errorMessage {
                Section {
                    ErrorNotice(message: error)
                    if model.hasPendingSave {
                        Text("Retry to confirm this save. Your original values are kept to avoid duplicates.")
                            .font(.footnote)
                        Button("Close and Check History", action: onClose).disabled(model.isSaving)
                        Text("The meal may already be saved. Check History before adding it again.").font(.footnote)
                    }
                }
            }
            Section {
                Button {
                    editing = false
                    guard let draft = editedDraft else { return }
                    Task { if let meal = await model.save(draft) { onSave(meal) } }
                } label: {
                    HStack {
                        Spacer()
                        if model.isSaving { ProgressView() }
                        Text(model.isSaving ? "Saving…" : model.hasPendingSave ? "Retry Save" : "Save Meal")
                            .font(.headline)
                        Spacer()
                    }
                }.disabled(editedDraft == nil || model.isSaving)
            }
        }
        .navigationTitle("Review Meal").navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(model.isSaving || model.hasPendingSave)
        .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { editing = false } } }
    }

    private func numberField(_ title: String, value: Binding<String>) -> some View {
        HStack {
            Text(title)
            TextField(title, text: value).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                .focused($editing).accessibilityLabel(title)
        }
    }
}
