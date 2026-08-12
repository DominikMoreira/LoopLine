import Observation
import SwiftData
import SwiftUI

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var project: Project
    @State private var viewModel = ProjectDetailViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                mediaHeader
                titleBlock
                statsRow
                readingActions
                notesSection
                trackingSection
                metadataSection
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
                viewModel.isShowingEditProject = true
            }
        }
        .sheet(isPresented: $viewModel.isShowingAddNote) {
            AddNoteView(currentRow: project.currentRow) { draft in
                viewModel.addNote(from: draft, to: project, in: modelContext)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .alert("Delete Project?", isPresented: $viewModel.isShowingDeleteConfirmation) {
            Button("Delete Project", role: .destructive) {
                viewModel.deleteProject(project, in: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete \(project.name) and its notes. This cannot be undone.")
        }
        .sheet(isPresented: $viewModel.isShowingEditProject) {
            EditProjectView(project: project)
        }
        .sheet(isPresented: $viewModel.isShowingTextImport) {
            PastedTextImportView(initialText: project.sourceText ?? "") { text in
                viewModel.importPastedText(text, into: project, in: modelContext)
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
                    Text(viewModel.sourceMetaText(for: project))
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
            LoopLineStatTile(value: viewModel.repeatDisplayText(for: project), label: "Repeat")
            Divider()
            LoopLineStatTile(value: String(project.currentStitch), label: "Stitches")
            Divider()
            LoopLineStatTile(value: viewModel.progressText(for: project), label: "Progress")
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
                    viewModel.isShowingTextImport = true
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
                viewModel.isShowingAddNote = true
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
                    detail: viewModel.rowDetailText(for: project),
                    canDecrease: project.currentRow > 1,
                    canIncrease: viewModel.canIncreaseRow(for: project),
                    decreaseAction: { viewModel.decrementRow(for: project, in: modelContext) },
                    increaseAction: { viewModel.incrementRow(for: project, in: modelContext) }
                )

                Divider()

                CounterControlRow(
                    title: "Repeat",
                    value: viewModel.repeatDisplayText(for: project),
                    detail: nil,
                    canDecrease: project.repeatCurrent > 1,
                    canIncrease: viewModel.canIncreaseRepeat(for: project),
                    decreaseAction: { viewModel.decrementRepeat(for: project, in: modelContext) },
                    increaseAction: { viewModel.incrementRepeat(for: project, in: modelContext) }
                )

                Divider()

                CounterControlRow(
                    title: "Stitches",
                    value: String(project.currentStitch),
                    detail: nil,
                    canDecrease: project.currentStitch > 1,
                    canIncrease: true,
                    decreaseAction: { viewModel.decrementStitch(for: project, in: modelContext) },
                    increaseAction: { viewModel.incrementStitch(for: project, in: modelContext) }
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

    private var secondaryActions: some View {
        HStack(spacing: 16) {
            Button("Edit Project") {
                viewModel.isShowingEditProject = true
            }
            .buttonStyle(LoopLineSecondaryButtonStyle())

            Button("Delete") {
                viewModel.isShowingDeleteConfirmation = true
            }
            .buttonStyle(LoopLineSecondaryButtonStyle(tint: .red))
        }
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

private struct EditProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project
    @State private var viewModel: EditProjectViewModel

    init(project: Project) {
        self.project = project
        _viewModel = State(initialValue: EditProjectViewModel(project: project))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                LoopLineFieldLabel(text: "Project name")
                TextField("Project name", text: $viewModel.draft.name)
                    .font(.title3)
                    .textFieldStyle(.plain)
                    .padding(16)
                    .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                LoopLineFieldLabel(text: "Subtitle")
                TextField("Subtitle", text: $viewModel.draft.subtitle)
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
                    .disabled(!viewModel.draft.isValid)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Save Project") {
                    saveProject()
                }
                .buttonStyle(LoopLinePrimaryButtonStyle())
                .disabled(!viewModel.draft.isValid)
                .opacity(viewModel.draft.isValid ? 1 : 0.45)
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 12)
                .background(.regularMaterial)
            }
        }
    }

    private func saveProject() {
        viewModel.saveProject(project, in: modelContext)
        dismiss()
    }
}

struct AddNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddNoteViewModel

    let onSave: (NoteDraft) -> Void

    init(currentRow: Int, onSave: @escaping (NoteDraft) -> Void) {
        _viewModel = State(initialValue: AddNoteViewModel(currentRow: currentRow))
        self.onSave = onSave
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    Capsule()
                        .fill(Color(.systemGray4))
                        .frame(width: 52, height: 5)
                        .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 12) {
                        LoopLineFieldLabel(text: "Note")
                        TextField("Start decreases at the armhole.", text: $viewModel.draft.text, axis: .vertical)
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
                        Toggle(
                            "Attach to a specific row?",
                            isOn: Binding(
                                get: { viewModel.attachesToRow },
                                set: { viewModel.setAttachesToRow($0) }
                            )
                        )
                        .font(.headline)

                        Text("Reminder will appear when you reach that row in reading mode.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if viewModel.attachesToRow {
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
                        onSave(viewModel.draft)
                    }
                    .disabled(!viewModel.draft.isValid)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Save Note") {
                    onSave(viewModel.draft)
                }
                .buttonStyle(LoopLinePrimaryButtonStyle())
                .disabled(!viewModel.draft.isValid)
                .opacity(viewModel.draft.isValid ? 1 : 0.45)
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 12)
                .background(.regularMaterial)
            }
        }
    }

    private var rowNumberEditor: some View {
        @Bindable var viewModel = viewModel

        return VStack(alignment: .leading, spacing: 12) {
            LoopLineFieldLabel(text: "Row number")

            HStack(spacing: 14) {
                TextField("Row", text: $viewModel.draft.rowNumberText)
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
                        viewModel.adjustRow(by: 1)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(LoopLineIconButtonStyle(size: 50))

                    Button {
                        viewModel.adjustRow(by: -1)
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
                    if let rowNumber = viewModel.draft.rowNumber {
                        Text("Row \(rowNumber)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(viewModel.draft.trimmedText.isEmpty ? "Your note preview will appear here." : viewModel.draft.trimmedText)
                        .font(.body)
                        .foregroundStyle(viewModel.draft.trimmedText.isEmpty ? .secondary : .primary)
                }

                Spacer()
            }
            .padding(16)
            .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
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
