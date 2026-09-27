import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class ProjectListViewModel {
    var isShowingCreateProject = false
    var projectPendingDeletion: Project?

    var isShowingDeleteConfirmation: Bool {
        get { projectPendingDeletion != nil }
        set {
            if !newValue {
                projectPendingDeletion = nil
            }
        }
    }

    var deleteConfirmationMessage: String {
        guard let projectPendingDeletion else {
            return "This will permanently delete this project and its notes. This cannot be undone."
        }

        return "This will permanently delete \(projectPendingDeletion.name) and its notes. This cannot be undone."
    }

    func showCreateProject() {
        isShowingCreateProject = true
    }

    func createProject(
        from draft: NewProjectDraft,
        in modelContext: ModelContext,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        guard draft.isValid, let sourceType = draft.sourceType else {
            throw CreateProjectError.invalidDraft
        }

        let project = Project(
            name: draft.trimmedName,
            subtitle: draft.trimmedSubtitle.isEmpty ? nil : draft.trimmedSubtitle,
            sourceType: sourceType,
            currentRow: 0,
            repeatCurrent: 0,
            currentStitch: 0,
            repeatTotal: nil,
            rows: sourceType == .text ? draft.rows : [],
            sourceText: sourceType == .text && !draft.trimmedSourceText.isEmpty ? draft.trimmedSourceText : nil,
            sourceFilePath: sourceFilePath(from: draft, sourceType: sourceType),
            notes: []
        )

        modelContext.insert(project)
        do {
            try save(modelContext)
            isShowingCreateProject = false
        } catch {
            modelContext.delete(project)
            throw error
        }
    }

    func requestDeletion(for project: Project) {
        projectPendingDeletion = project
    }

    func confirmProjectDeletion(in modelContext: ModelContext) {
        guard let project = projectPendingDeletion else { return }
        projectPendingDeletion = nil
        ProjectCleanupService.deleteImportedSource(for: project)
        modelContext.delete(project)
        save(modelContext)
    }

    private func sourceFilePath(from draft: NewProjectDraft, sourceType: ImportSource) -> String? {
        switch sourceType {
        case .pdf:
            draft.sourceFilePath
        case .image:
            draft.imageFilePath
        case .text:
            nil
        }
    }

    private func save(_ modelContext: ModelContext) {
        try? modelContext.save()
    }
}

private enum CreateProjectError: Error {
    case invalidDraft
}
