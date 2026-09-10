import Foundation
import Observation

@MainActor @Observable
final class MealViewModel {
    var imageData: Data?
    var draft: MealDraft?
    var errorMessage: String?
    private(set) var isAnalyzing = false
    private(set) var isSaving = false
    private var requestID = UUID()
    private var pendingSave: MealDraft?
    private let api: any MealAPI

    init(api: any MealAPI) { self.api = api }

    func analyze() async {
        guard let imageData, !isAnalyzing else { return }
        isAnalyzing = true
        errorMessage = nil
        defer { isAnalyzing = false }
        do {
            let result = try await api.analyze(image: imageData)
            guard !Task.isCancelled else { return }
            guard result.isValid else { throw APIError.invalidResponse }
            draft = result
            requestID = UUID()
            pendingSave = nil
        } catch {
            if !Task.isCancelled { errorMessage = error.localizedDescription }
        }
    }

    func save(_ edited: MealDraft) async -> Meal? {
        guard edited.isValid, !isSaving else { return nil }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        // Freeze the payload after an uncertain response. Retrying the same ID is safe.
        if pendingSave == nil { pendingSave = edited }
        do {
            return try await api.save(pendingSave!, requestID: requestID)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    var hasPendingSave: Bool { pendingSave != nil }
}
