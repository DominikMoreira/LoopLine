import SwiftData
import SwiftUI

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var project: Project
    @State private var isShowingAddNote = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingEditProject = false
    @State private var isShowingTextImport = false

    private var totalRows: Int {
        project.rows.count
    }

    private var progress: Double? {
        guard totalRows > 0 else { return nil }
        let clampedRow = min(max(project.currentRow, 1), totalRows)
        return Double(clampedRow) / Double(totalRows)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                mediaHeader
                titleBlock
                statsRow
                readingActions
                notesSection
                trackingSection
                metadataSection
                #if DEBUG
                developmentSection
                #endif
                secondaryActions
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 36)
        }
        .background(LoopLineTheme.appBackground)
        .navigationTitle("Project")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") {
                isShowingEditProject = true
            }
        }
        .sheet(isPresented: $isShowingAddNote) {
            AddNoteView(currentRow: project.currentRow) { draft in
                addNote(from: draft)
                isShowingAddNote = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
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
        .sheet(isPresented: $isShowingTextImport) {
            PastedTextImportView(initialText: project.sourceText ?? "") { text in
                importPastedText(text)
                isShowingTextImport = false
            }
        }
    }

    private var mediaHeader: some View {
        Group {
            if project.sourceType == .image, let sourceFilePath = project.sourceFilePath {
                StoredImagePreview(storedReference: sourceFilePath, height: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.secondary.opacity(0.28), lineWidth: 1)
                    }
            } else {
                LoopLineSourcePlaceholder(sourceType: project.sourceType, label: "Cover Image")
                    .frame(height: 190)
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(project.name)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                LoopLineSourceBadge(sourceType: project.sourceType)

                if let subtitle = project.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else {
                    Text(sourceMetaText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            LoopLineStatTile(value: String(project.currentRow), label: "Current Row")
            Divider()
            LoopLineStatTile(value: repeatDisplayText, label: "Repeat")
            Divider()
            LoopLineStatTile(value: String(project.currentStitch), label: "Stitches")
            Divider()
            LoopLineStatTile(value: progressText, label: "Progress")
        }
        .frame(maxWidth: .infinity)
        .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
        }
    }

    private var readingActions: some View {
        VStack(spacing: 12) {
            NavigationLink {
                readingDestination
            } label: {
                Text("Open Reading Mode")
            }
            .buttonStyle(LoopLinePrimaryButtonStyle())

            if project.sourceType == .text {
                Button("Import Pasted Text") {
                    isShowingTextImport = true
                }
                .buttonStyle(LoopLineSecondaryButtonStyle())
            }
        }
    }

    @ViewBuilder
    private var readingDestination: some View {
        switch project.sourceType {
        case .pdf:
            PDFReadingView(project: project)
        case .image:
            ImageReadingView(project: project)
        case .text:
            ReadingModeView(project: project)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LoopLineSectionHeader(title: "Notes & Reminders", actionTitle: "+ Add") {
                isShowingAddNote = true
            }

            if project.notes.isEmpty {
                Text("No notes yet")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                VStack(spacing: 14) {
                    ForEach(project.notes) { note in
                        NoteRow(note: note)
                    }
                }
            }
        }
    }

    private var trackingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LoopLineSectionHeader(title: "Tracking")

            VStack(spacing: 0) {
                CounterControlRow(
                    title: "Current Row",
                    value: String(project.currentRow),
                    detail: totalRows > 0 ? "of \(totalRows) rows" : nil,
                    canDecrease: project.currentRow > 1,
                    canIncrease: canIncreaseRow,
                    decreaseAction: decrementRow,
                    increaseAction: incrementRow
                )

                Divider()

                CounterControlRow(
                    title: "Repeat",
                    value: repeatDisplayText,
                    detail: nil,
                    canDecrease: project.repeatCurrent > 1,
                    canIncrease: canIncreaseRepeat,
                    decreaseAction: decrementRepeat,
                    increaseAction: incrementRepeat
                )

                Divider()

                CounterControlRow(
                    title: "Stitches",
                    value: String(project.currentStitch),
                    detail: nil,
                    canDecrease: project.currentStitch > 1,
                    canIncrease: true,
                    decreaseAction: decrementStitch,
                    increaseAction: incrementStitch
                )
            }
            .padding(.horizontal, 16)
            .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LoopLineSectionHeader(title: "Source")

            VStack(spacing: 12) {
                DetailRow(label: "Source Type", value: project.sourceType.displayName)

                if project.sourceType == .pdf, let sourceFilePath = project.sourceFilePath {
                    DetailRow(label: "PDF", value: URL(fileURLWithPath: sourceFilePath).lastPathComponent)
                }

                if project.sourceType == .image, let sourceFilePath = project.sourceFilePath {
                    DetailRow(label: "Image", value: URL(fileURLWithPath: sourceFilePath).lastPathComponent)
                }

                DetailRow(label: "Notes", value: String(project.notes.count))
            }
            .padding(16)
            .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    #if DEBUG
    private var developmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LoopLineSectionHeader(title: "Development")
            Button("Load Sample Pattern") {
                loadSamplePattern()
            }
            .buttonStyle(LoopLineSecondaryButtonStyle())

            Text("Temporary test content. Delete after reading mode scroll testing.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    #endif

    private var secondaryActions: some View {
        HStack(spacing: 16) {
            Button("Edit Project") {
                isShowingEditProject = true
            }
            .buttonStyle(LoopLineSecondaryButtonStyle())

            Button("Delete") {
                isShowingDeleteConfirmation = true
            }
            .buttonStyle(LoopLineSecondaryButtonStyle(tint: .red))
        }
    }

    private var sourceMetaText: String {
        if let detailMeta = project.detailMeta, !detailMeta.isEmpty {
            return detailMeta
        }

        return totalRows > 0 ? "\(totalRows) rows" : project.sourceType.displayName
    }

    private var progressText: String {
        guard let progress else { return "--" }
        return progress.formatted(.percent.precision(.fractionLength(0)))
    }

    private var repeatDisplayText: String {
        if let repeatTotal = project.repeatTotal {
            "\(project.repeatCurrent) of \(repeatTotal)"
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

    private func incrementStitch() {
        project.currentStitch += 1
        saveChanges()
    }

    private func decrementStitch() {
        guard project.currentStitch > 1 else { return }
        project.currentStitch -= 1
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
        if project.sourceType == .pdf {
            ImportedPDFStorage.delete(storedReference: project.sourceFilePath)
        } else if project.sourceType == .image {
            ImportedImageStorage.delete(storedReference: project.sourceFilePath)
        }

        modelContext.delete(project)
        saveChanges()
        dismiss()
    }

    private func importPastedText(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        project.sourceType = .text
        project.sourceText = trimmedText
        project.sourceFilePath = nil
        project.coverImagePath = nil
        project.rows = PatternTextNormalizer.rows(from: trimmedText)
        project.currentRow = min(max(project.currentRow, 1), project.rows.count)
        saveChanges()
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

struct NoteDraft {
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

struct PastedTextImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String

    let onImport: (String) -> Void

    init(initialText: String, onImport: @escaping (String) -> Void) {
        _text = State(initialValue: initialText)
        self.onImport = onImport
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canImport: Bool {
        !trimmedText.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                LoopLineFieldLabel(text: "Pattern Text")
                TextEditor(text: $text)
                    .frame(minHeight: 280)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                    }
                    .textInputAutocapitalization(.sentences)

                Text("Each non-empty line becomes a tracked row.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(24)
            .navigationTitle("Import Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        onImport(trimmedText)
                    }
                    .disabled(!canImport)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Import Text") {
                    onImport(trimmedText)
                }
                .buttonStyle(LoopLinePrimaryButtonStyle())
                .disabled(!canImport)
                .opacity(canImport ? 1 : 0.45)
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 12)
                .background(.regularMaterial)
            }
        }
    }
}

private struct EditProjectDraft {
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
            VStack(alignment: .leading, spacing: 16) {
                LoopLineFieldLabel(text: "Project name")
                TextField("Project name", text: $draft.name)
                    .font(.title3)
                    .textFieldStyle(.plain)
                    .padding(16)
                    .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                LoopLineFieldLabel(text: "Subtitle")
                TextField("Subtitle", text: $draft.subtitle)
                    .textFieldStyle(.plain)
                    .padding(16)
                    .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Spacer()
            }
            .padding(24)
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
            .safeAreaInset(edge: .bottom) {
                Button("Save Project") {
                    saveProject()
                }
                .buttonStyle(LoopLinePrimaryButtonStyle())
                .disabled(!draft.isValid)
                .opacity(draft.isValid ? 1 : 0.45)
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 12)
                .background(.regularMaterial)
            }
        }
    }

    private func saveProject() {
        project.name = draft.trimmedName
        project.subtitle = draft.trimmedSubtitle.isEmpty ? nil : draft.trimmedSubtitle
        try? modelContext.save()
        dismiss()
    }
}

struct AddNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: NoteDraft
    @State private var attachesToRow: Bool

    let onSave: (NoteDraft) -> Void

    init(currentRow: Int, onSave: @escaping (NoteDraft) -> Void) {
        _draft = State(initialValue: NoteDraft(text: "", rowNumberText: String(currentRow)))
        _attachesToRow = State(initialValue: true)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    Capsule()
                        .fill(Color(.systemGray4))
                        .frame(width: 52, height: 5)
                        .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 12) {
                        LoopLineFieldLabel(text: "Note")
                        TextField("Start decreases at the armhole.", text: $draft.text, axis: .vertical)
                            .lineLimit(4...7)
                            .textFieldStyle(.plain)
                            .padding(16)
                            .frame(minHeight: 116, alignment: .topLeading)
                            .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                            }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Attach to a specific row?", isOn: $attachesToRow)
                            .font(.headline)
                            .onChange(of: attachesToRow) { _, isAttached in
                                if !isAttached {
                                    draft.rowNumberText = ""
                                }
                            }

                        Text("Reminder will appear when you reach that row in reading mode.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if attachesToRow {
                        rowNumberEditor
                    }

                    previewSection
                }
                .padding(24)
                .padding(.bottom, 96)
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
            .safeAreaInset(edge: .bottom) {
                Button("Save Note") {
                    onSave(draft)
                }
                .buttonStyle(LoopLinePrimaryButtonStyle())
                .disabled(!draft.isValid)
                .opacity(draft.isValid ? 1 : 0.45)
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 12)
                .background(.regularMaterial)
            }
        }
    }

    private var rowNumberEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            LoopLineFieldLabel(text: "Row number")

            HStack(spacing: 14) {
                TextField("Row", text: $draft.rowNumberText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .font(.title3.monospacedDigit())
                    .padding(16)
                    .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.secondary.opacity(0.28), lineWidth: 1)
                    }

                VStack(spacing: 10) {
                    Button {
                        adjustRow(by: 1)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(LoopLineIconButtonStyle(size: 50))

                    Button {
                        adjustRow(by: -1)
                    } label: {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(LoopLineIconButtonStyle(size: 50))
                }
            }

            Text("Example: On row 12, start decreases")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LoopLineFieldLabel(text: "Preview")

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "flag.fill")
                    .foregroundStyle(.yellow)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 2) {
                    if let rowNumber = draft.rowNumber {
                        Text("Row  \(rowNumber)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(draft.trimmedText.isEmpty ? "Your note preview will appear here." : draft.trimmedText)
                        .font(.body)
                        .foregroundStyle(draft.trimmedText.isEmpty ? .secondary : .primary)
                }

                Spacer()
            }
            .padding(16)
            .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func adjustRow(by offset: Int) {
        let currentValue = draft.rowNumber ?? 1
        draft.rowNumberText = String(max(1, currentValue + offset))
    }
}

private struct NoteRow: View {
    let note: ProjectNote

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(rowBadgeText)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 50, height: 42)
                .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.secondary.opacity(0.28), lineWidth: 1)
                }

            Text(note.text)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    private var rowBadgeText: String {
        if let rowNumber = note.rowNumber {
            return "R\(rowNumber)"
        }
        return "Note"
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(value)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .font(.subheadline)
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
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: decreaseAction) {
                Image(systemName: "minus")
            }
            .buttonStyle(LoopLineIconButtonStyle(size: 42))
            .disabled(!canDecrease)

            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(minWidth: 58)

            Button(action: increaseAction) {
                Image(systemName: "plus")
            }
            .buttonStyle(LoopLineIconButtonStyle(size: 42))
            .disabled(!canIncrease)
        }
        .padding(.vertical, 12)
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

#Preview("Import Text") {
    PastedTextImportView(
        initialText: "Cast on 24 stitches.\nKnit every row until piece measures 48 inches.\nBind off loosely.",
        onImport: { _ in }
    )
}
