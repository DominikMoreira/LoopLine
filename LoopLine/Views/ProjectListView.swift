import SwiftData
import SwiftUI

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) private var projects: [Project]
    @State private var isShowingCreateProject = false

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

    private var projectList: some View {
        List(projects) { project in
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
                            Text(label(for: sourceType))
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

    private func label(for sourceType: ImportSource) -> String {
        switch sourceType {
        case .pdf:
            "PDF"
        case .image:
            "Image"
        case .text:
            "Text"
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
