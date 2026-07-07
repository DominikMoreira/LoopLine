import PDFKit
import SwiftUI

struct PDFReadingView: View {
    let project: Project

    private var pdfURL: URL? {
        guard project.sourceType == .pdf, let sourceFilePath = project.sourceFilePath else {
            return nil
        }

        return ImportedPDFStorage.fileURL(for: sourceFilePath)
    }

    var body: some View {
        Group {
            if let pdfURL {
                VStack(spacing: 0) {
                    PDFKitView(url: pdfURL)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(LoopLineTheme.readingStroke, lineWidth: 1)
                        }
                        .padding(16)

                    Text("Pinch to zoom - drag to pan")
                        .font(.caption.monospaced())
                        .foregroundStyle(LoopLineTheme.readingSecondaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(LoopLineTheme.mediaHintBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(.bottom, 16)
                }
                .background(LoopLineTheme.readingBackground.ignoresSafeArea())
            } else {
                ContentUnavailableView(
                    "PDF Unavailable",
                    systemImage: "doc.richtext",
                    description: Text("The imported PDF could not be found.")
                )
            }
        }
        .navigationTitle("Reading Mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(LoopLineTheme.readingBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

private struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .clear
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.autoScales = true

        if pdfView.document == nil {
            pdfView.document = PDFDocument(url: url)
        }
    }
}

#Preview("PDF Missing") {
    NavigationStack {
        PDFReadingView(project: Project(
            name: "PDF Pattern",
            sourceType: .pdf,
            sourceFilePath: "/missing/pattern.pdf"
        ))
    }
}
