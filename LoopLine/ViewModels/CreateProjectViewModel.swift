import Foundation
import Observation
import PhotosUI
import SwiftUI

struct NewProjectDraft {
    var name = ""
    var subtitle = ""
    var sourceType: ImportSource = .text
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
        }
    }

    mutating func setPastedText(_ text: String) {
        sourceText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        rows = PatternTextNormalizer.rows(from: sourceText)
    }

    mutating func clearPastedText() {
        sourceText = ""
        rows = []
    }

    mutating func setPDF(path: String, fileName: String) {
        sourceFilePath = path
        sourceFileName = fileName
    }

    mutating func clearPDF() {
        sourceFilePath = nil
        sourceFileName = nil
    }

    mutating func setImage(path: String, fileName: String) {
        imageFilePath = path
        imageFileName = fileName
    }

    mutating func clearImage() {
        imageFilePath = nil
        imageFileName = nil
    }
}

@MainActor
@Observable
final class CreateProjectViewModel {
    var draft = NewProjectDraft()
    var isShowingTextImport = false
    var isShowingPDFImporter = false
    var selectedImageItem: PhotosPickerItem?
    var pdfImportError: String?
    var imageImportError: String?
    var isImportingImage = false
    var didCreateProject = false

    @ObservationIgnored private var imageImportTask: Task<Void, Never>?
    @ObservationIgnored private var currentImageImportID: UUID?
    @ObservationIgnored private var isDraftActive = true

    var canCreateProject: Bool {
        draft.isValid && !isImportingImage
    }

    func markCreated() {
        didCreateProject = true
    }

    func setPastedText(_ text: String) {
        draft.setPastedText(text)
        isShowingTextImport = false
    }

    func showPDFImporter() {
        pdfImportError = nil
        isShowingPDFImporter = true
    }

    func selectSourceType(_ sourceType: ImportSource) {
        draft.sourceType = sourceType
        handleSourceTypeChange(sourceType)
    }

    func importPDF(from result: Result<URL, Error>) {
        do {
            let sourceURL = try result.get()
            let localURL = try ImportedPDFStorage.copyIntoStorage(from: sourceURL)
            ImportedPDFStorage.delete(storedReference: draft.sourceFilePath)
            draft.setPDF(path: localURL.lastPathComponent, fileName: sourceURL.lastPathComponent)
            pdfImportError = nil
        } catch {
            pdfImportError = "Could not import the selected PDF."
        }
    }

    func importImage(from item: PhotosPickerItem?) {
        guard let item else { return }

        imageImportTask?.cancel()
        let importID = UUID()
        currentImageImportID = importID
        isImportingImage = true
        imageImportError = nil

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
                          self.currentImageImportID == importID,
                          self.draft.sourceType == .image else {
                        return
                    }

                    ImportedImageStorage.delete(storedReference: self.draft.imageFilePath)
                    self.draft.setImage(path: localReference, fileName: localReference)
                    self.selectedImageItem = nil
                    self.isImportingImage = false
                    self.imageImportTask = nil
                    self.currentImageImportID = nil
                    didAdoptImage = true
                }

                if !didAdoptImage {
                    ImportedImageStorage.delete(storedReference: localReference)
                }
            } catch is CancellationError {
                await MainActor.run {
                    guard let self, self.currentImageImportID == importID else { return }
                    self.selectedImageItem = nil
                    self.isImportingImage = false
                    self.imageImportTask = nil
                    self.currentImageImportID = nil
                }
            } catch {
                await MainActor.run {
                    guard let self, self.isDraftActive, self.currentImageImportID == importID else { return }
                    self.imageImportError = "Could not import the selected image."
                    self.selectedImageItem = nil
                    self.isImportingImage = false
                    self.imageImportTask = nil
                    self.currentImageImportID = nil
                }
            }
        }
    }

    func cleanupDraftFilesIfNeeded() {
        guard !didCreateProject else { return }
        cleanupDraftFiles()
    }

    func cleanupDraftFiles() {
        isDraftActive = false
        imageImportTask?.cancel()
        imageImportTask = nil
        currentImageImportID = nil
        isImportingImage = false
        selectedImageItem = nil

        ProjectCleanupService.deleteDraftFiles(
            pdfReference: draft.sourceFilePath,
            imageReference: draft.imageFilePath
        )
    }

    private func handleSourceTypeChange(_ sourceType: ImportSource) {
        if sourceType != .text {
            draft.clearPastedText()
            isShowingTextImport = false
        }

        if sourceType != .pdf {
            ImportedPDFStorage.delete(storedReference: draft.sourceFilePath)
            draft.clearPDF()
            isShowingPDFImporter = false
            pdfImportError = nil
        }

        if sourceType != .image {
            imageImportTask?.cancel()
            imageImportTask = nil
            currentImageImportID = nil
            ImportedImageStorage.delete(storedReference: draft.imageFilePath)
            draft.clearImage()
            selectedImageItem = nil
            imageImportError = nil
            isImportingImage = false
        }
    }
}
