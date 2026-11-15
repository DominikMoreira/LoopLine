import Foundation

enum ProjectCleanupService {
    static func deleteImportedSource(for project: Project) {
        switch project.sourceType {
        case .pdf:
            ImportedPDFStorage.delete(storedReference: project.sourceFilePath)
        case .image:
            ImportedImageStorage.delete(storedReferences: project.imageReferences)
        case .text:
            break
        }
    }

    static func deleteDraftFiles(pdfReference: String?, imageReferences: [String]) {
        ImportedPDFStorage.delete(storedReference: pdfReference)
        ImportedImageStorage.delete(storedReferences: imageReferences)
    }
}
