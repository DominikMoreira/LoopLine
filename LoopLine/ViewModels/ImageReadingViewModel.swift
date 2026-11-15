import Foundation
import SwiftData

@MainActor
struct ImageReadingViewModel {
    func imageReferences(for project: Project) -> [String] {
        project.imageReferences.filter { ImportedImageStorage.fileURL(for: $0) != nil }
    }

    func restoreReadingPosition(for project: Project) -> ImageReadingPosition {
        ImageReadingPosition(
            pageIndex: max(project.lastImagePageIndex, 0),
            verticalPosition: min(max(project.lastImagePageVerticalPosition, 0), 1)
        )
    }

    func saveReadingPosition(
        _ position: ImageReadingPosition,
        for project: Project,
        in modelContext: ModelContext
    ) {
        guard project.lastImagePageIndex != position.pageIndex ||
                project.lastImagePageVerticalPosition != position.verticalPosition else {
            return
        }

        project.lastImagePageIndex = position.pageIndex
        project.lastImagePageVerticalPosition = position.verticalPosition
        try? modelContext.save()
    }
}

struct ImageReadingPosition: Equatable {
    let pageIndex: Int
    let verticalPosition: Double
}
