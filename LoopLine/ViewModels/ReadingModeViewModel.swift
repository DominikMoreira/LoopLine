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

    func totalRows(for project: Project) -> Int {
        project.rows.count
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
            return "Row \(project.currentRow) - \(note.text)"
        }
        return "Row \(project.currentRow) - no reminders"
    }

    func canIncreaseRow(for project: Project) -> Bool {
        let totalRows = totalRows(for: project)
        return totalRows == 0 || project.currentRow < totalRows - 1
    }

    func canIncreaseRepeat(for project: Project) -> Bool {
        guard let repeatTotal = project.repeatTotal else { return true }
        return project.repeatCurrent < max(repeatTotal - 1, 0)
    }

    func selectRow(at index: Int, in project: Project, modelContext: ModelContext) {
        guard project.rows.indices.contains(index) else { return }
        project.currentRow = index
        save(modelContext)
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

    func resetCounters(for project: Project, in modelContext: ModelContext) {
        project.currentRow = 0
        project.repeatCurrent = 0
        project.currentStitch = 0
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
