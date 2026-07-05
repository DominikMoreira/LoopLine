import SwiftData
import SwiftUI

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
            rows: draft.rows,
            sourceText: draft.sourceType == .text && !trimmedSourceText.isEmpty ? trimmedSourceText : nil,
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
    var rows: [String] = []

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct CreateProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft = NewProjectDraft()

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
