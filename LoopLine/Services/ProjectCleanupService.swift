import Foundation

enum ProjectCleanupService {
    static func deleteImportedSource(for project: Project) {
        switch project.sourceType {
        case .pdf:
            ImportedPDFStorage.delete(storedReference: project.sourceFilePath)
        case .image:
            ImportedImageStorage.delete(storedReference: project.sourceFilePath)
        case .text:
            break
        }
    }

    static func deleteDraftFiles(pdfReference: String?, imageReference: String?) {
        ImportedPDFStorage.delete(storedReference: pdfReference)
        ImportedImageStorage.delete(storedReference: imageReference)
    }
}
