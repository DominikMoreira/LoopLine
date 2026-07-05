import SwiftData
import SwiftUI

struct ReadingModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project
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

    private var activeRowIndex: Int? {
        guard !project.rows.isEmpty else { return nil }
        return min(max(project.currentRow, 1), project.rows.count) - 1
    }

    var body: some View {
        ScrollViewReader { proxy in
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
            .navigationTitle(project.name)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                scrollToActiveRow(with: proxy)
            }
            .onChange(of: project.currentRow) { _, _ in
                scrollToActiveRow(with: proxy)
            }
        }
    }

    private var rowContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(project.rows.enumerated()), id: \.offset) { index, row in
                ReadingRow(
                    rowNumber: index + 1,
                    text: row,
                    isActive: index == activeRowIndex,
                    usesLargeControls: appSettings.largeControls,
                    guideOpacity: appSettings.guideOpacity,
                    selectAction: {
                        selectRow(at: index)
                    }
                )
                .id(index)
            }
        }
        .font(readableFont)
    }

    private func sourceTextContent(_ sourceText: String) -> some View {
        Text(sourceText)
            .font(readableFont)
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

    private func selectRow(at index: Int) {
        guard project.rows.indices.contains(index) else { return }
        project.currentRow = index + 1
        try? modelContext.save()
    }

    private func scrollToActiveRow(with proxy: ScrollViewProxy) {
        guard let activeRowIndex else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            proxy.scrollTo(activeRowIndex, anchor: .center)
        }
    }
}

private struct ReadingRow: View {
    let rowNumber: Int
    let text: String
    let isActive: Bool
    let usesLargeControls: Bool
    let guideOpacity: Double
    let selectAction: () -> Void

    private var verticalPadding: CGFloat {
        usesLargeControls ? 14 : 8
    }

    private var horizontalPadding: CGFloat {
        usesLargeControls ? 14 : 10
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(rowNumber).")
                .foregroundStyle(isActive ? .primary : .secondary)
                .fontWeight(isActive ? .semibold : .regular)
                .monospacedDigit()

            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)
        .background {
            if isActive {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.16 * guideOpacity))
            }
        }
        .overlay {
            if isActive {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor.opacity(0.45 * guideOpacity), lineWidth: 1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: selectAction)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Sets this as the current row")
    }
}

#Preview("Rows") {
    NavigationStack {
        ReadingModeView(project: Project(
            name: "Sample Scarf",
            sourceType: .text,
            currentRow: 2,
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
