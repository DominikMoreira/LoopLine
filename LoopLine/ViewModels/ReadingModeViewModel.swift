import Foundation
import Observation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class ReadingModeViewModel {
    var isShowingAddNote = false
    var isShowingResetConfirmation = false

    func trimmedSourceText(for project: Project) -> String? {
        guard let sourceText = project.sourceText?.trimmingCharacters(in: .whitespacesAndNewlines), !sourceText.isEmpty else {
            return nil
        }
        return sourceText
    }

    func readableFont(for appSettings: AppSettings) -> Font {
        appSettings.largeControls ? .title3 : .body
    }

    func activeRowIndex(for project: Project) -> Int? {
        guard !project.rows.isEmpty else { return nil }
        return min(max(project.currentRow, 0), project.rows.count - 1)
    }

    func currentRowNotes(for project: Project) -> [ProjectNote] {
        project.notes.filter { $0.rowNumber == project.currentRow }
    }

    func reminderText(for project: Project) -> String {
        if let note = currentRowNotes(for: project).first {
            return String(
                localized: "Row \(project.currentRow) - \(note.text)",
                comment: "Current row followed by its reminder text."
            )
        }
        return String(
            localized: "Row \(project.currentRow) - no reminders",
            comment: "Current row with a message indicating that it has no reminders."
        )
    }

    func selectRow(at index: Int, in project: Project, modelContext: ModelContext) {
        guard project.rows.indices.contains(index), project.currentRow != index else { return }
        project.currentRow = index
        project.recordLastCounterChange(metric: .row, value: index, direction: .set)
        save(modelContext)
    }

    func resetCounters(for project: Project, in modelContext: ModelContext) {
        let didChange = project.currentRow != 0 || project.repeatCurrent != 0 || project.currentStitch != 0
        project.currentRow = 0
        project.repeatCurrent = 0
        project.currentStitch = 0
        if didChange {
            project.clearLastCounterChange()
        }
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

    func updateNote(_ note: ProjectNote, from draft: NoteDraft, in modelContext: ModelContext) {
        note.text = draft.trimmedText
        note.rowNumber = draft.rowNumber
        save(modelContext)
    }

    func deleteNote(_ note: ProjectNote, in modelContext: ModelContext) {
        modelContext.delete(note)
        save(modelContext)
    }

    func scrollToActiveRow(for project: Project, with proxy: ScrollViewProxy) {
        guard let activeRowIndex = activeRowIndex(for: project) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            proxy.scrollTo(activeRowIndex, anchor: .center)
        }
    }

    private func save(_ modelContext: ModelContext) {
        try? modelContext.save()
    }
}
