import AVFoundation
import PhotosUI
import SwiftUI

struct AddMealView: View {
    @State private var model: MealViewModel
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var isLoadingPhoto = false
    @State private var photoTask: Task<Void, Never>?
    @State private var analysisTask: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss
    let onSave: (Meal) -> Void

    init(api: any MealAPI, onSave: @escaping (Meal) -> Void) {
        _model = State(initialValue: MealViewModel(api: api))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let data = model.imageData, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFit()
                            .frame(maxHeight: 300).clipShape(RoundedRectangle(cornerRadius: 24))
                            .accessibilityLabel("Selected meal photo")
                    } else {
                        ContentUnavailableView("What's on your plate?", systemImage: "camera.viewfinder",
                                               description: Text("A clear photo helps estimate your meal's nutrition."))
                    }
                    HStack {
                        Button { Task { await openCamera() } } label: {
                            Label("Take Photo", systemImage: "camera")
                        }
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Choose Photo", systemImage: "photo")
                        }
                    }.buttonStyle(.bordered).disabled(model.isAnalyzing || isLoadingPhoto)
                    if isLoadingPhoto { ProgressView("Preparing photo…") }
                    Text("Your photo will be sent to Google Gemini to estimate nutrition. You can edit the result before saving.")
                        .font(.footnote).foregroundStyle(.secondary)
                    if let error = model.errorMessage { ErrorNotice(message: error) }
                    Button {
                        analysisTask = Task { await model.analyze() }
                    } label: {
                        HStack {
                            if model.isAnalyzing { ProgressView().tint(.white) }
                            Text(model.isAnalyzing ? "Analyzing meal…" : "Estimate Nutrition")
                        }.frame(maxWidth: .infinity).padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.imageData == nil || model.isAnalyzing || isLoadingPhoto)
                }.padding()
            }
            .navigationTitle("Add Meal").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(model.isSaving || model.hasPendingSave)
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraPicker { data in
                    photoTask?.cancel()
                    photoTask = Task { await prepare(data) }
                }.ignoresSafeArea()
            }
            .onChange(of: selectedPhoto) { _, item in
                photoTask?.cancel()
                photoTask = Task {
                    isLoadingPhoto = true
                    model.imageData = nil
                    do {
                        let data = try await item?.loadTransferable(type: Data.self)
                        guard !Task.isCancelled else { return }
                        await prepare(data)
                    } catch {
                        if !Task.isCancelled {
                            isLoadingPhoto = false
                            model.errorMessage = "The photo could not be downloaded. Please try again."
                        }
                    }
                }
            }
            .navigationDestination(isPresented: Binding(get: { model.draft != nil }, set: { if !$0 { model.draft = nil } })) {
                if let draft = model.draft {
                    MealResultView(model: model, draft: draft, onClose: { dismiss() }) { meal in
                        onSave(meal)
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled(model.isSaving || model.hasPendingSave)
        .onDisappear { photoTask?.cancel(); analysisTask?.cancel() }
    }

    private func prepare(_ data: Data?) async {
        isLoadingPhoto = true
        model.imageData = nil
        model.errorMessage = nil
        do {
            guard let data else { throw ImageService.ImageError.unreadable }
            let prepared = try await Task.detached(priority: .userInitiated) { try ImageService.prepare(data) }.value
            guard !Task.isCancelled else { return }
            model.imageData = prepared
        } catch {
            if !Task.isCancelled { model.errorMessage = error.localizedDescription }
        }
        if !Task.isCancelled { isLoadingPhoto = false }
    }

    private func openCamera() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            model.errorMessage = "A camera is unavailable on this device. Choose a photo instead."
            return
        }
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        let allowed: Bool
        if status == .notDetermined { allowed = await AVCaptureDevice.requestAccess(for: .video) }
        else { allowed = status == .authorized }
        if allowed { showingCamera = true }
        else { model.errorMessage = "Camera access is disabled. Enable it in iPhone Settings, or choose a photo." }
    }
}
