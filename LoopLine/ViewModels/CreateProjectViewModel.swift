import Foundation
import Observation
import PhotosUI
import SwiftUI

struct NewProjectDraft {
    var name = ""
    var subtitle = ""
    var sourceType: ImportSource?
    var sourceText = ""
    var sourceFilePath: String?
    var sourceFileName: String?
    var imageFilePath: String?
    var imageFileName: String?
    var rows: [String] = []

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedSubtitle: String {
        subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedSourceText: String {
        sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        !trimmedName.isEmpty && hasRequiredSource
    }

    private var hasRequiredSource: Bool {
        switch sourceType {
        case .text:
            !trimmedSourceText.isEmpty
        case .pdf:
            sourceFilePath != nil
        case .image:
            imageFilePath != nil
        case nil:
            false
        }
    }

    mutating func setPastedText(_ text: String) {
        sourceType = .text
        sourceText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        rows = PatternTextNormalizer.rows(from: sourceText)
        clearPDF()
        clearImage()
    }

    mutating func setPDF(path: String, fileName: String) {
        sourceType = .pdf
        sourceFilePath = path
        sourceFileName = fileName
        clearPastedText()
        clearImage()
    }

    mutating func setImage(path: String, fileName: String) {
        sourceType = .image
        imageFilePath = path
        imageFileName = fileName
        clearPastedText()
        clearPDF()
    }

    mutating func removeSource() {
        sourceType = nil
        clearPastedText()
        clearPDF()
        clearImage()
    }

    private mutating func clearPastedText() {
        sourceText = ""
        rows = []
    }

    private mutating func clearPDF() {
        sourceFilePath = nil
        sourceFileName = nil
    }

    private mutating func clearImage() {
        imageFilePath = nil
        imageFileName = nil
    }
}

@MainActor
@Observable
final class CreateProjectViewModel {
    var draft = NewProjectDraft()
    var isShowingTextEditor = false
    var isShowingPDFImporter = false
    var isShowingPhotoPicker = false
    var isShowingReplacementOptions = false
    var selectedImageItem: PhotosPickerItem?
    var errorMessage: String?
    var isImportingPDF = false
    var isImportingImage = false
    var isSaving = false
    var didCreateProject = false

    @ObservationIgnored private var imageImportTask: Task<Void, Never>?
    @ObservationIgnored private var currentImageImportID: UUID?
    @ObservationIgnored private var isDraftActive = true

    var canCreateProject: Bool {
        draft.isValid && !isImportingPDF && !isImportingImage && !isSaving
    }

    func showTextEditor() {
        errorMessage = nil
        isShowingTextEditor = true
    }

    func showPDFImporter() {
        errorMessage = nil
        isShowingPDFImporter = true
    }

    func showPhotoPicker() {
        errorMessage = nil
        isShowingPhotoPicker = true
    }

    func savePatternText(_ text: String) {
        replaceCurrentSource {
            draft.setPastedText(text)
        }
        isShowingTextEditor = false
    }

    func importPDF(from result: Result<URL, Error>) {
        guard !isCancellation(result) else { return }

        isImportingPDF = true
        defer { isImportingPDF = false }

        do {
            let sourceURL = try result.get()
            let localURL = try ImportedPDFStorage.copyIntoStorage(from: sourceURL)
            adoptPDF(path: localURL.lastPathComponent, fileName: sourceURL.lastPathComponent)
            errorMessage = nil
        } catch {
            errorMessage = String(localized: "Could not import the selected PDF.")
        }
    }

    func adoptPDF(path: String, fileName: String) {
        replaceCurrentSource {
            draft.setPDF(path: path, fileName: fileName)
        }
    }

    func importImage(from item: PhotosPickerItem?) {
        guard let item else { return }

        imageImportTask?.cancel()
        let importID = UUID()
        currentImageImportID = importID
        isImportingImage = true
        errorMessage = nil

        imageImportTask = Task { [weak self] in
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                try Task.checkCancellation()

                let localURL = try ImportedImageStorage.saveImageData(data)
                let localReference = localURL.lastPathComponent
                var didAdoptImage = false

                await MainActor.run {
                    guard let self,
                          self.isDraftActive,
                          self.currentImageImportID == importID else {
                        return
                    }

                    self.adoptImage(path: localReference, fileName: localReference)
                    self.finishImageImport()
                    didAdoptImage = true
                }

                if !didAdoptImage {
                    ImportedImageStorage.delete(storedReference: localReference)
                }
            } catch is CancellationError {
                await MainActor.run {
                    guard let self, self.currentImageImportID == importID else { return }
                    self.finishImageImport()
                }
            } catch {
                await MainActor.run {
                    guard let self, self.isDraftActive, self.currentImageImportID == importID else { return }
                    self.errorMessage = String(localized: "Could not import the selected photo.")
                    self.finishImageImport()
                }
            }
        }
    }

    func adoptImage(path: String, fileName: String) {
        replaceCurrentSource {
            draft.setImage(path: path, fileName: fileName)
        }
    }

    func removeSelectedSource() {
        deleteStoredFilesForCurrentSource()
        draft.removeSource()
        errorMessage = nil
    }

    func createProject(using create: (NewProjectDraft) throws -> Void) {
        guard canCreateProject else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            try create(draft)
            didCreateProject = true
        } catch {
            errorMessage = String(localized: "Could not create the project. Please try again.")
        }
    }

    func cleanupDraftFilesIfNeeded() {
        guard !didCreateProject else { return }
        cleanupDraftFiles()
    }

    func cleanupDraftFiles() {
        isDraftActive = false
        imageImportTask?.cancel()
        finishImageImport()
        ProjectCleanupService.deleteDraftFiles(
            pdfReference: draft.sourceFilePath,
            imageReference: draft.imageFilePath
        )
    }

    private func replaceCurrentSource(_ update: () -> Void) {
        deleteStoredFilesForCurrentSource()
        update()
        isShowingReplacementOptions = false
    }

    private func deleteStoredFilesForCurrentSource() {
        switch draft.sourceType {
        case .pdf:
            ImportedPDFStorage.delete(storedReference: draft.sourceFilePath)
        case .image:
            ImportedImageStorage.delete(storedReference: draft.imageFilePath)
        case .text, nil:
            break
        }
    }

    private func finishImageImport() {
        selectedImageItem = nil
        isImportingImage = false
        imageImportTask = nil
        currentImageImportID = nil
    }

    private func isCancellation(_ result: Result<URL, Error>) -> Bool {
        guard case .failure(let error) = result else { return false }
        let cocoaError = error as? CocoaError
        return cocoaError?.code == .userCancelled
    }
}
