import SwiftData
import SwiftUI

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) private var projects: [Project]

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
                Button("Add Sample", action: addSampleProject)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Projects Yet", systemImage: "tray")
        } description: {
            Text("Add a sample project to check the app foundation.")
        } actions: {
            Button("Add Sample Project", action: addSampleProject)
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

    private func addSampleProject() {
        let sampleProject = Project(
            name: "Sample Scarf",
            subtitle: "Beginner garter stitch",
            sourceType: .text,
            currentRow: 1,
            repeatCurrent: 1,
            repeatTotal: 4,
            rows: [
                "Cast on 24 stitches.",
                "Knit every stitch across.",
                "Turn and repeat until desired length."
            ],
            sourceText: "Cast on 24 stitches. Knit every stitch across."
        )

        modelContext.insert(sampleProject)
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
