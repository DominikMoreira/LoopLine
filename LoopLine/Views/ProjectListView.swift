import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) private var projects: [Project]
    @State private var isShowingCreateProject = false
    @State private var projectPendingDeletion: Project?

    var body: some View {
        NavigationStack {
            Group {
                if projects.isEmpty {
                    emptyState
                } else {
                    projectList
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                Button("Add Project") {
                    isShowingCreateProject = true
                }
            }
            .sheet(isPresented: $isShowingCreateProject) {
                CreateProjectView { draft in
                    createProject(from: draft)
                    isShowingCreateProject = false
                }
            }
            .alert("Delete Project?", isPresented: deleteConfirmationBinding) {
                Button("Delete Project", role: .destructive) {
                    confirmProjectDeletion()
                }
                Button("Cancel", role: .cancel) {
                    projectPendingDeletion = nil
                }
            } message: {
                Text(deleteConfirmationMessage)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Projects Yet", systemImage: "tray")
        } description: {
            Text("Create your first knitting project to start tracking rows.")
        } actions: {
            Button("Add Project") {
                isShowingCreateProject = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { projectPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    projectPendingDeletion = nil
                }
            }
        )
    }

    private var deleteConfirmationMessage: String {
        guard let projectPendingDeletion else {
            return "This will permanently delete this project and its notes. This cannot be undone."
        }

        return "This will permanently delete \(projectPendingDeletion.name) and its notes. This cannot be undone."
    }

    private var projectList: some View {
        List(projects) { project in
            NavigationLink {
                ProjectDetailView(project: project)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)

                    if let subtitle = project.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("Current row: \(project.currentRow)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button("Delete Project", role: .destructive) {
                    projectPendingDeletion = project
                }
            }
        }
    }

    private func createProject(from draft: NewProjectDraft) {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSubtitle = draft.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSourceText = draft.sourceText.trimmingCharacters(in: .whitespacesAndNewlines)

        let project = Project(
            name: trimmedName,
            subtitle: trimmedSubtitle.isEmpty ? nil : trimmedSubtitle,
            sourceType: draft.sourceType,
            currentRow: 1,
            repeatCurrent: 1,
            repeatTotal: nil,
            rows: draft.sourceType == .text ? draft.rows : [],
            sourceText: draft.sourceType == .text && !trimmedSourceText.isEmpty ? trimmedSourceText : nil,
            sourceFilePath: draft.sourceType == .pdf ? draft.sourceFilePath : nil,
            notes: []
        )

        modelContext.insert(project)
    }

    private func confirmProjectDeletion() {
        guard let project = projectPendingDeletion else { return }
        projectPendingDeletion = nil
        deleteProject(project)
    }

    private func deleteProject(_ project: Project) {
        modelContext.delete(project)
        try? modelContext.save()
    }
}

private struct NewProjectDraft {
    var name = ""
    var subtitle = ""
    var sourceType: ImportSource = .text
    var sourceText = ""
    var sourceFilePath: String?
    var sourceFileName: String?
    var rows: [String] = []

    var trimmedSourceText: String {
        sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasName && hasRequiredSource
    }

    private var hasRequiredSource: Bool {
        switch sourceType {
        case .text:
            !trimmedSourceText.isEmpty
        case .pdf:
            sourceFilePath != nil
        case .image:
            true
        }
    }

    mutating func setPastedText(_ text: String) {
        sourceText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        rows = PatternTextNormalizer.rows(from: sourceText)
    }

    mutating func clearPastedText() {
        sourceText = ""
        rows = []
    }

    mutating func setPDF(path: String, fileName: String) {
        sourceFilePath = path
        sourceFileName = fileName
    }

}

private struct CreateProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft = NewProjectDraft()
    @State private var isShowingTextImport = false
    @State private var isShowingPDFImporter = false
    @State private var pdfImportError: String?

    let onCreate: (NewProjectDraft) -> Void

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
                    .onChange(of: draft.sourceType) { _, newSourceType in
                        handleSourceTypeChange(newSourceType)
                    }
                }

                if draft.sourceType == .text {
                    Section("Pasted Text") {
                        Button(draft.trimmedSourceText.isEmpty ? "Enter Pasted Text" : "Edit Pasted Text") {
                            isShowingTextImport = true
                        }

                        if draft.rows.isEmpty {
                            Text("Pattern text is required for pasted text projects.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("\(draft.rows.count) rows ready to import")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if draft.sourceType == .pdf {
                    Section("PDF") {
                        Button(draft.sourceFileName == nil ? "Choose PDF" : "Choose Different PDF") {
                            pdfImportError = nil
                            isShowingPDFImporter = true
                        }

                        if let sourceFileName = draft.sourceFileName {
                            Text(sourceFileName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("A PDF is required for PDF projects.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let pdfImportError {
                            Text(pdfImportError)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(draft)
                    }
                    .disabled(!draft.isValid)
                }
            }
            .sheet(isPresented: $isShowingTextImport) {
                PastedTextImportView(initialText: draft.sourceText) { text in
                    draft.setPastedText(text)
                    isShowingTextImport = false
                }
            }
            .fileImporter(
                isPresented: $isShowingPDFImporter,
                allowedContentTypes: [.pdf]
            ) { result in
                importPDF(from: result)
            }
        }
    }

    private func importPDF(from result: Result<URL, Error>) {
        do {
            let sourceURL = try result.get()
            let localURL = try ImportedPDFStorage.copyIntoStorage(from: sourceURL)
            draft.setPDF(path: localURL.lastPathComponent, fileName: localURL.lastPathComponent)
            pdfImportError = nil
        } catch {
            pdfImportError = "Could not import the selected PDF."
        }
    }

    private func handleSourceTypeChange(_ sourceType: ImportSource) {
        if sourceType != .text {
            draft.clearPastedText()
            isShowingTextImport = false
        }
    }

}

#Preview("Empty") {
    ProjectListView()
        .modelContainer(PreviewModelContainer.make())
}

#Preview("With Project") {
    let container = PreviewModelContainer.make()
    let context = container.mainContext

    context.insert(Project(
        name: "Sample Scarf",
        subtitle: "Beginner garter stitch",
        sourceType: .text,
        currentRow: 3,
        repeatCurrent: 1,
        repeatTotal: 4,
        rows: ["Cast on", "Knit", "Bind off"]
    ))

    return ProjectListView()
        .modelContainer(container)
}
