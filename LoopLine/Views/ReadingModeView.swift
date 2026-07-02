import SwiftData
import SwiftUI

struct ReadingModeView: View {
    let project: Project
    @Query private var settings: [AppSettings]

    private var appSettings: AppSettings {
        settings.first ?? AppSettings()
    }

    private var trimmedSourceText: String? {
        guard let sourceText = project.sourceText?.trimmingCharacters(in: .whitespacesAndNewlines), !sourceText.isEmpty else {
            return nil
        }
        return sourceText
    }

    private var readableFont: Font {
        appSettings.largeControls ? .title3 : .body
    }

    private var foregroundStyle: Color {
        appSettings.readingDarkMode ? .white : .primary
    }

    private var backgroundStyle: Color {
        appSettings.readingDarkMode ? .black : .clear
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !project.rows.isEmpty {
                    rowContent
                } else if let trimmedSourceText {
                    sourceTextContent(trimmedSourceText)
                } else {
                    emptyContent
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(backgroundStyle)
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var rowContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(project.rows.enumerated()), id: \.offset) { index, row in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1).")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Text(row)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .font(readableFont)
        .foregroundStyle(foregroundStyle)
    }

    private func sourceTextContent(_ sourceText: String) -> some View {
        Text(sourceText)
            .font(readableFont)
            .foregroundStyle(foregroundStyle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
    }

    private var emptyContent: some View {
        ContentUnavailableView(
            "No Pattern Content",
            systemImage: "doc.text",
            description: Text("No pattern content is available yet.")
        )
        .frame(maxWidth: .infinity, minHeight: 240)
    }
}

#Preview("Rows") {
    NavigationStack {
        ReadingModeView(project: Project(
            name: "Sample Scarf",
            sourceType: .text,
            rows: [
                "Cast on 24 stitches.",
                "Knit every stitch across the row.",
                "Turn and repeat until the scarf reaches the desired length."
            ]
        ))
    }
    .modelContainer(PreviewModelContainer.make())
}

#Preview("Source Text") {
    NavigationStack {
        ReadingModeView(project: Project(
            name: "Text Pattern",
            sourceType: .text,
            sourceText: "Cast on 24 stitches.\n\nKnit every row until the piece measures 48 inches. Bind off loosely."
        ))
    }
    .modelContainer(PreviewModelContainer.make())
}

#Preview("Empty") {
    NavigationStack {
        ReadingModeView(project: Project(
            name: "Empty Project",
            sourceType: .pdf
        ))
    }
    .modelContainer(PreviewModelContainer.make())
}
