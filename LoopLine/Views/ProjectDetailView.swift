import SwiftData
import SwiftUI

struct ProjectDetailView: View {
    let project: Project

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
            statsSection
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
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

    private var statsSection: some View {
        Section("Stats") {
            DetailRow(label: "Current Row", value: String(project.currentRow))
            DetailRow(label: "Repeat Current", value: String(project.repeatCurrent))

            if let repeatTotal = project.repeatTotal {
                DetailRow(label: "Repeat Total", value: String(repeatTotal))
            }

            DetailRow(label: "Total Rows", value: String(totalRows))

            if let progress {
                DetailRow(label: "Progress", value: progress.formatted(.percent.precision(.fractionLength(0))))
            }

            DetailRow(label: "Notes", value: String(project.notes.count))
        }
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
