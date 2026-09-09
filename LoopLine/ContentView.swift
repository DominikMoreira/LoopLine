import SwiftData
import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]

    var body: some View {
        TabView {
            ProjectListView()
                .tabItem {
                    Label("Projects", systemImage: "folder")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(LoopLineTheme.accent)
        .onAppear(perform: prepareAppData)
    }

    private func prepareAppData() {
        ensureDefaultSettings()
        ensureUITestProjectIfNeeded()
    }

    private func ensureDefaultSettings() {
        guard settings.isEmpty else { return }
        modelContext.insert(AppSettings())
        try? modelContext.save()
    }

    private func ensureUITestProjectIfNeeded() {
        guard CommandLine.arguments.contains("-uiTesting") else { return }

        do {
            let descriptor = FetchDescriptor<Project>()
            let existingProjects = try modelContext.fetch(descriptor)
            guard existingProjects.isEmpty else { return }

            let pdfURL = try makeUITestPDFURL()
            modelContext.insert(Project(
                name: "UI Test PDF Project",
                subtitle: "Prepared UI test project",
                detailMeta: "PDF",
                sourceType: .pdf,
                currentRow: 1,
                repeatCurrent: 0,
                repeatTotal: 1,
                rows: ["Row 1: Knit all stitches."],
                sourceFilePath: pdfURL.path
            ))
            try modelContext.save()
        } catch {
            fatalError("Failed to prepare UI test PDF project: \(error)")
        }
    }

    private func makeUITestPDFURL() throws -> URL {
        let pdfURL = FileManager.default.temporaryDirectory.appendingPathComponent("LoopLine-UITest-Pattern.pdf")
        guard !FileManager.default.fileExists(atPath: pdfURL.path) else { return pdfURL }

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        try renderer.writePDF(to: pdfURL) { context in
            context.beginPage()

            let text = "LoopLine UI Test Pattern\n\nRow 1: Knit all stitches."
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            text.draw(at: CGPoint(x: 72, y: 72), withAttributes: attributes)
        }

        return pdfURL
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewModelContainer.make())
}
