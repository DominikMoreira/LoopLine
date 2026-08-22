import Foundation
import Observation
import SwiftData

struct NoteDraft {
    var text = ""
    var rowNumberText = ""

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var rowNumber: Int? {
        let trimmedRow = rowNumberText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRow.isEmpty, let rowNumber = Int(trimmedRow), rowNumber >= 0 else {
            return nil
        }
        return rowNumber
    }

    var isValid: Bool {
        !trimmedText.isEmpty && hasValidRowNumber
    }

    private var hasValidRowNumber: Bool {
        let trimmedRow = rowNumberText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedRow.isEmpty || rowNumber != nil
    }
}

struct EditProjectDraft {
    var name: String
    var subtitle: String

    init(project: Project) {
        name = project.name
        subtitle = project.subtitle ?? ""
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedSubtitle: String {
        subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        !trimmedName.isEmpty
    }
}

@MainActor
@Observable
final class ProjectDetailViewModel {
    var isShowingAddNote = false
    var isShowingDeleteConfirmation = false
    var isShowingEditProject = false
    var isShowingTextImport = false

    func totalRows(for project: Project) -> Int {
        project.rows.count
    }

    func progress(for project: Project) -> Double? {
        let totalRows = totalRows(for: project)
        guard totalRows > 0 else { return nil }
        let maxRowIndex = totalRows - 1
        let clampedRow = min(max(project.currentRow, 0), maxRowIndex)
        guard maxRowIndex > 0 else { return 1 }
        return Double(clampedRow) / Double(maxRowIndex)
    }

    func sourceMetaText(for project: Project) -> String {
        if let detailMeta = project.detailMeta, !detailMeta.isEmpty {
            return detailMeta
        }

        let totalRows = totalRows(for: project)
        return totalRows > 0 ? "\(totalRows) rows" : project.sourceType.displayName
    }

    func progressText(for project: Project) -> String {
        guard let progress = progress(for: project) else { return "--" }
        return progress.formatted(.percent.precision(.fractionLength(0)))
    }

    func repeatDisplayText(for project: Project) -> String {
        if let repeatTotal = project.repeatTotal {
            "\(project.repeatCurrent) of \(repeatTotal)"
        } else {
            String(project.repeatCurrent)
        }
    }

    func rowDetailText(for project: Project) -> String? {
        let totalRows = totalRows(for: project)
        return totalRows > 0 ? "of \(totalRows) rows" : nil
    }

    func canIncreaseRow(for project: Project) -> Bool {
        let totalRows = totalRows(for: project)
        return totalRows == 0 || project.currentRow < totalRows - 1
    }

    func canIncreaseRepeat(for project: Project) -> Bool {
        guard let repeatTotal = project.repeatTotal else { return true }
        return project.repeatCurrent < max(repeatTotal - 1, 0)
    }

    func incrementRow(for project: Project, in modelContext: ModelContext) {
        guard canIncreaseRow(for: project) else { return }
        project.currentRow += 1
        save(modelContext)
    }

    func decrementRow(for project: Project, in modelContext: ModelContext) {
        guard project.currentRow > 0 else { return }
        project.currentRow -= 1
        save(modelContext)
    }

    func incrementRepeat(for project: Project, in modelContext: ModelContext) {
        guard canIncreaseRepeat(for: project) else { return }
        project.repeatCurrent += 1
        save(modelContext)
    }

    func decrementRepeat(for project: Project, in modelContext: ModelContext) {
        guard project.repeatCurrent > 0 else { return }
        project.repeatCurrent -= 1
        save(modelContext)
    }

    func incrementStitch(for project: Project, in modelContext: ModelContext) {
        project.currentStitch += 1
        save(modelContext)
    }

    func decrementStitch(for project: Project, in modelContext: ModelContext) {
        guard project.currentStitch > 0 else { return }
        project.currentStitch -= 1
        save(modelContext)
    }

    func addNote(from draft: NoteDraft, to project: Project, in modelContext: ModelContext) {
        let note = ProjectNote(
            text: draft.trimmedText,
            rowNumber: draft.rowNumber
        )

        modelContext.insert(note)
        project.notes.append(note)
        save(modelContext)
        isShowingAddNote = false
    }

    func deleteProject(_ project: Project, in modelContext: ModelContext) {
        ProjectCleanupService.deleteImportedSource(for: project)
        modelContext.delete(project)
        save(modelContext)
    }

    func importPastedText(_ text: String, into project: Project, in modelContext: ModelContext) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        project.sourceType = .text
        project.sourceText = trimmedText
        project.sourceFilePath = nil
        project.coverImagePath = nil
        project.rows = PatternTextNormalizer.rows(from: trimmedText)
        project.currentRow = clampedCurrentRow(for: project)
        save(modelContext)
        isShowingTextImport = false
    }

    private func clampedCurrentRow(for project: Project) -> Int {
        guard !project.rows.isEmpty else { return 0 }
        return min(max(project.currentRow, 0), project.rows.count - 1)
    }

    private func save(_ modelContext: ModelContext) {
        try? modelContext.save()
    }
}

@MainActor
@Observable
final class EditProjectViewModel {
    var draft: EditProjectDraft

    init(project: Project) {
        draft = EditProjectDraft(project: project)
    }

    func saveProject(_ project: Project, in modelContext: ModelContext) {
        project.name = draft.trimmedName
        project.subtitle = draft.trimmedSubtitle.isEmpty ? nil : draft.trimmedSubtitle
        try? modelContext.save()
    }
}

@MainActor
@Observable
final class AddNoteViewModel {
    var draft: NoteDraft
    var attachesToRow: Bool

    init(currentRow: Int) {
        draft = NoteDraft(text: "", rowNumberText: String(currentRow))
        attachesToRow = true
    }

    func setAttachesToRow(_ isAttached: Bool) {
        attachesToRow = isAttached
        if !isAttached {
            draft.rowNumberText = ""
        }
    }

    func adjustRow(by offset: Int) {
        let currentValue = draft.rowNumber ?? 0
        draft.rowNumberText = String(max(0, currentValue + offset))
    }
}
