import Foundation

struct ImageReadingViewModel {
    func imageReference(for project: Project) -> String? {
        guard project.sourceType == .image,
              let sourceFilePath = project.sourceFilePath,
              ImportedImageStorage.fileURL(for: sourceFilePath) != nil else {
            return nil
        }

        return sourceFilePath
    }
}
