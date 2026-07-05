import SwiftData
import SwiftUI

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var project: Project
    @State private var isShowingAddNote = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingEditProject = false

    private var totalRows: Int {
        project.rows.count
    }

    private var progress: Double? {
        guard totalRows > 0 else { return nil }
        let clampedRow = min(max(project.currentRow, 1), totalRows)
        return Double(clampedRow) / Double(totalRows)
    }

    var body: some View {
        List {
            headerSection
            metadataSection
            readingSection
            #if DEBUG
            developmentSection
            #endif
            trackingSection
            statsSection
            notesSection
            deleteSection
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") {
                isShowingEditProject = true
            }

            Button("Add Note") {
                isShowingAddNote = true
            }
        }
        .sheet(isPresented: $isShowingAddNote) {
            AddNoteView { draft in
                addNote(from: draft)
                isShowingAddNote = false
            }
        }
        .alert("Delete Project?", isPresented: $isShowingDeleteConfirmation) {
            Button("Delete Project", role: .destructive) {
                deleteProject()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete \(project.name) and its notes. This cannot be undone.")
        }
        .sheet(isPresented: $isShowingEditProject) {
            EditProjectView(project: project)
        }
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text(project.name)
                    .font(.title2)
                    .fontWeight(.semibold)

                if let subtitle = project.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var metadataSection: some View {
        Section("Metadata") {
            DetailRow(label: "Source Type", value: project.sourceType.displayName)
        }
    }

    private var readingSection: some View {
        Section {
            NavigationLink("Open Reading Mode") {
                ReadingModeView(project: project)
            }
        }
    }

    #if DEBUG
    private var developmentSection: some View {
        Section("Development") {
            Button("Load Sample Pattern") {
                loadSamplePattern()
            }
            Text("Temporary test content. Delete after reading mode scroll testing.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    #endif

    private var trackingSection: some View {
        Section("Tracking") {
            CounterControlRow(
                title: "Current Row",
                value: String(project.currentRow),
                detail: totalRows > 0 ? "of \(totalRows) rows" : nil,
                canDecrease: project.currentRow > 1,
                canIncrease: canIncreaseRow,
                decreaseAction: decrementRow,
                increaseAction: incrementRow
            )

            CounterControlRow(
                title: "Repeat",
                value: repeatDisplayText,
                detail: nil,
                canDecrease: project.repeatCurrent > 1,
                canIncrease: canIncreaseRepeat,
                decreaseAction: decrementRepeat,
                increaseAction: incrementRepeat
            )
        }
    }

    private var statsSection: some View {
        Section("Stats") {
            DetailRow(label: "Total Rows", value: String(totalRows))

            if let progress {
                DetailRow(label: "Progress", value: progress.formatted(.percent.precision(.fractionLength(0))))
            }

            DetailRow(label: "Notes", value: String(project.notes.count))
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            if project.notes.isEmpty {
                Text("No notes yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(project.notes) { note in
                    NoteRow(note: note)
                }
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button("Delete Project", role: .destructive) {
                isShowingDeleteConfirmation = true
            }
        }
    }

    private var repeatDisplayText: String {
        if let repeatTotal = project.repeatTotal {
            "\(project.repeatCurrent) / \(repeatTotal)"
        } else {
            String(project.repeatCurrent)
        }
    }

    private var canIncreaseRow: Bool {
        totalRows == 0 || project.currentRow < totalRows
    }

    private var canIncreaseRepeat: Bool {
        guard let repeatTotal = project.repeatTotal else { return true }
        return project.repeatCurrent < repeatTotal
    }

    private func incrementRow() {
        guard canIncreaseRow else { return }
        project.currentRow += 1
        saveChanges()
    }

    private func decrementRow() {
        guard project.currentRow > 1 else { return }
        project.currentRow -= 1
        saveChanges()
    }

    private func incrementRepeat() {
        guard canIncreaseRepeat else { return }
        project.repeatCurrent += 1
        saveChanges()
    }

    private func decrementRepeat() {
        guard project.repeatCurrent > 1 else { return }
        project.repeatCurrent -= 1
        saveChanges()
    }

    private func addNote(from draft: NoteDraft) {
        let note = ProjectNote(
            text: draft.trimmedText,
            rowNumber: draft.rowNumber
        )

        modelContext.insert(note)
        project.notes.append(note)
        saveChanges()
    }

    private func deleteProject() {
        modelContext.delete(project)
        saveChanges()
        dismiss()
    }

    #if DEBUG
    private func loadSamplePattern() {
        project.rows = Self.samplePatternRows
        project.sourceText = Self.samplePatternRows.joined(separator: "\n")
        project.currentRow = min(max(project.currentRow, 1), project.rows.count)
        saveChanges()
    }
    #endif

    private func saveChanges() {
        try? modelContext.save()
    }

    #if DEBUG
    // TODO: Delete after reading mode scroll behavior testing.
    private static let samplePatternRows = [
        "CO 60 sts.",
        "Row 1: K2, P2 across.",
        "Row 2: P2, K2 across.",
        "Row 3: K all sts.",
        "Row 4: P all sts.",
        "Row 5: K4, P2 across.",
        "Row 6: P4, K2 across.",
        "Row 7: K1, P1 rib across.",
        "Row 8: P1, K1 rib across.",
        "Row 9: K all sts, increasing 4 sts evenly.",
        "Row 10: P all sts.",
        "Row 11: K6, cable 4 front, K6; repeat across.",
        "Row 12: P all sts.",
        "Row 13: K all sts.",
        "Row 14: P all sts.",
        "Row 15: K2, P2 across.",
        "Row 16: P2, K2 across.",
        "Repeat Rows 1-16 until piece measures 20 cm.",
        "Bind off loosely in pattern."
    ]
    #endif
}

private struct NoteDraft {
    var text = ""
    var rowNumberText = ""

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var rowNumber: Int? {
        let trimmedRow = rowNumberText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRow.isEmpty, let rowNumber = Int(trimmedRow), rowNumber > 0 else {
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

private struct EditProjectDraft {
    var name: String
    var subtitle: String
    var sourceType: ImportSource

    init(project: Project) {
        name = project.name
        subtitle = project.subtitle ?? ""
        sourceType = project.sourceType
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

private struct EditProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project
    @State private var draft: EditProjectDraft

    init(project: Project) {
        self.project = project
        _draft = State(initialValue: EditProjectDraft(project: project))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Project name", text: $draft.name)
                    TextField("Subtitle", text: $draft.subtitle)

                    Picker("Source Type", selection: $draft.sourceType) {
                        ForEach(ImportSource.allCases, id: \.self) { sourceType in
                            Text(sourceType.displayName)
                                .tag(sourceType)
                        }
                    }
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProject()
                    }
                    .disabled(!draft.isValid)
                }
            }
        }
    }

    private func saveProject() {
        project.name = draft.trimmedName
        project.subtitle = draft.trimmedSubtitle.isEmpty ? nil : draft.trimmedSubtitle
        project.sourceType = draft.sourceType
        clearStaleSourceFields()
        try? modelContext.save()
        dismiss()
    }

    private func clearStaleSourceFields() {
        if draft.sourceType != .text {
            project.sourceText = nil
        }

        if draft.sourceType != .pdf {
            project.sourceFilePath = nil
        }

        if draft.sourceType != .image {
            project.coverImagePath = nil
        }
    }
}

private struct AddNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft = NoteDraft()

    let onSave: (NoteDraft) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Note text", text: $draft.text, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Row number", text: $draft.rowNumberText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                    }
                    .disabled(!draft.isValid)
                }
            }
        }
    }
}

private struct NoteRow: View {
    let note: ProjectNote

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.text)

            if let rowNumber = note.rowNumber {
                Text("Row \(rowNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct CounterControlRow: View {
    let title: String
    let value: String
    let detail: String?
    let canDecrease: Bool
    let canIncrease: Bool
    let decreaseAction: () -> Void
    let increaseAction: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: decreaseAction) {
                Image(systemName: "minus.circle")
                    .imageScale(.large)
            }
            .buttonStyle(.borderless)
            .disabled(!canDecrease)
            .accessibilityLabel("Decrease \(title)")

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
                .frame(minWidth: 44)

            Button(action: increaseAction) {
                Image(systemName: "plus.circle")
                    .imageScale(.large)
            }
            .buttonStyle(.borderless)
            .disabled(!canIncrease)
            .accessibilityLabel("Increase \(title)")
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(project: Project(
            name: "Sample Scarf",
            subtitle: "Beginner garter stitch",
            sourceType: .text,
            currentRow: 3,
            repeatCurrent: 1,
            repeatTotal: 4,
            rows: ["Cast on", "Knit", "Bind off"],
            notes: [
                ProjectNote(text: "Check tension", rowNumber: 2)
            ]
        ))
    }
    .modelContainer(PreviewModelContainer.make())
}

#Preview("Edit Project") {
    let container = PreviewModelContainer.make()
    let project = Project(
        name: "Sample Scarf",
        subtitle: "Beginner garter stitch",
        sourceType: .text
    )
    container.mainContext.insert(project)

    return EditProjectView(project: project)
        .modelContainer(container)
}
