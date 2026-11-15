import Foundation
import Observation
import PhotosUI
import SwiftUI

struct NewProjectDraft {
    var name = ""
    var subtitleSize = ""
    var subtitleNeedleSize = ""
    var subtitleYarnType = ""
    var sourceType: ImportSource?
    var sourceText = ""
    var sourceFilePath: String?
    var sourceFileName: String?
    var imageFilePaths: [String] = []
    var rows: [String] = []

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedSubtitleSize: String {
        subtitleSize.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedSubtitleNeedleSize: String {
        subtitleNeedleSize.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedSubtitleYarnType: String {
        subtitleYarnType.trimmingCharacters(in: .whitespacesAndNewlines)
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
            !imageFilePaths.isEmpty
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

    mutating func setImages(paths: [String]) {
        sourceType = .image
        imageFilePaths = paths
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
        imageFilePaths = []
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
    var selectedImageItems: [PhotosPickerItem] = []
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
            let localURL = try ImportedPDFStorage.copyIntoStorage(
                from: sourceURL
            )
            adoptPDF(
                path: localURL.lastPathComponent,
                fileName: sourceURL.lastPathComponent
            )
            errorMessage = nil
        } catch {
            errorMessage = String(
                localized: "Could not import the selected PDF."
            )
        }
    }

    func adoptPDF(path: String, fileName: String) {
        replaceCurrentSource {
            draft.setPDF(path: path, fileName: fileName)
        }
    }

    func importImages(from items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }

        imageImportTask?.cancel()
        let importID = UUID()
        currentImageImportID = importID
        isImportingImage = true
        errorMessage = nil

        imageImportTask = Task { [weak self] in
            var localReferences: [String] = []
            do {
                for item in items {
                    guard
                        let data = try await item.loadTransferable(
                            type: Data.self
                        )
                    else {
                        throw CocoaError(.fileReadCorruptFile)
                    }
                    try Task.checkCancellation()

                    let localURL = try ImportedImageStorage.saveImageData(data)
                    localReferences.append(localURL.lastPathComponent)
                }

                var didAdoptImages = false

                await MainActor.run {
                    guard let self,
                        self.isDraftActive,
                        self.currentImageImportID == importID
                    else {
                        return
                    }

                    self.adoptImages(paths: localReferences)
                    self.finishImageImport()
                    didAdoptImages = true
                }

                if !didAdoptImages {
                    ImportedImageStorage.delete(
                        storedReferences: localReferences
                    )
                }
            } catch is CancellationError {
                ImportedImageStorage.delete(storedReferences: localReferences)
                await MainActor.run {
                    guard let self, self.currentImageImportID == importID else {
                        return
                    }
                    self.finishImageImport()
                }
            } catch {
                ImportedImageStorage.delete(storedReferences: localReferences)
                await MainActor.run {
                    guard let self, self.isDraftActive,
                        self.currentImageImportID == importID
                    else { return }
                    self.errorMessage = String(
                        localized: "Could not import the selected photos."
                    )
                    self.finishImageImport()
                }
            }
        }
    }

    func adoptImages(paths: [String]) {
        replaceCurrentSource {
            draft.setImages(paths: paths)
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
            errorMessage = String(
                localized: "Could not create the project. Please try again."
            )
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
            imageReferences: draft.imageFilePaths
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
            ImportedImageStorage.delete(storedReferences: draft.imageFilePaths)
        case .text, nil:
            break
        }
    }

    private func finishImageImport() {
        selectedImageItems = []
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
