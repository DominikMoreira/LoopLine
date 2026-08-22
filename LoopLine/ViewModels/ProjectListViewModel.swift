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

    func createProject(from draft: NewProjectDraft, in modelContext: ModelContext) {
        let project = Project(
            name: draft.trimmedName,
            subtitle: draft.trimmedSubtitle.isEmpty ? nil : draft.trimmedSubtitle,
            sourceType: draft.sourceType,
            currentRow: 0,
            repeatCurrent: 0,
            currentStitch: 0,
            repeatTotal: nil,
            rows: draft.sourceType == .text ? draft.rows : [],
            sourceText: draft.sourceType == .text && !draft.trimmedSourceText.isEmpty ? draft.trimmedSourceText : nil,
            sourceFilePath: sourceFilePath(from: draft),
            notes: []
        )

        modelContext.insert(project)
        save(modelContext)
        isShowingCreateProject = false
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

    private func sourceFilePath(from draft: NewProjectDraft) -> String? {
        switch draft.sourceType {
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
