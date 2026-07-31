import PDFKit
import PencilKit
import SwiftUI

struct PDFReadingView: View {
    let project: Project

    @State private var isMarkupActive = false
    @State private var markupError: PDFMarkupError?

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
                    PDFKitView(
                        url: pdfURL,
                        isMarkupActive: isMarkupActive,
                        markupError: $markupError
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isMarkupActive ? .yellow.opacity(0.75) : LoopLineTheme.readingStroke, lineWidth: isMarkupActive ? 2 : 1)
                    }
                    .padding(16)

                    Text(markupHintText)
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
        .toolbar {
            Button {
                isMarkupActive.toggle()
            } label: {
                Label("Markup", systemImage: isMarkupActive ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle")
            }
            .accessibilityLabel(isMarkupActive ? "Turn Markup Off" : "Turn Markup On")
        }
        .alert(item: $markupError) { error in
            Alert(
                title: Text("Markup Not Saved"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var markupHintText: String {
        isMarkupActive
        ? "Choose a tool from the palette, then draw with finger or Apple Pencil"
        : "Pinch to zoom - drag to pan"
    }
}

private struct PDFMarkupError: Identifiable {
    let id = UUID()
    let message: String
}

private final class PDFMarkupPDFView: PDFView {
    override var canBecomeFirstResponder: Bool {
        true
    }
}

private final class PDFMarkupCanvasView: PKCanvasView {
    override var canBecomeFirstResponder: Bool {
        true
    }
}

private struct PDFKitView: UIViewRepresentable {
    let url: URL
    let isMarkupActive: Bool
    @Binding var markupError: PDFMarkupError?

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url, markupError: $markupError)
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFMarkupPDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .clear
        pdfView.document = PDFDocument(url: url)

        if #available(iOS 16.0, *) {
            pdfView.pageOverlayViewProvider = context.coordinator
        }

        context.coordinator.configure(pdfView: pdfView, isMarkupActive: isMarkupActive)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.autoScales = true

        if context.coordinator.url != url || pdfView.document == nil {
            context.coordinator.reset(for: url)
            pdfView.document = PDFDocument(url: url)
        }

        context.coordinator.configure(pdfView: pdfView, isMarkupActive: isMarkupActive)
    }

    static func dismantleUIView(_ pdfView: PDFView, coordinator: Coordinator) {
        coordinator.teardown()
    }

    final class Coordinator: NSObject, PDFPageOverlayViewProvider, PKCanvasViewDelegate {
        var url: URL

        private var isMarkupActive = false
        private var markupError: Binding<PDFMarkupError?>
        private var storage: PDFMarkupStorage
        private let toolPicker = PKToolPicker()
        private let defaultMarkupTool = PKInkingTool(.marker, color: UIColor.systemYellow.withAlphaComponent(0.55), width: 14)
        private weak var pdfView: PDFView?
        private var canvasesByPage = [PDFPage: PKCanvasView]()
        private var pageIndexesByCanvas = [ObjectIdentifier: Int]()
        private var pendingSavesByCanvas = [ObjectIdentifier: DispatchWorkItem]()

        init(url: URL, markupError: Binding<PDFMarkupError?>) {
            self.url = url
            self.storage = PDFMarkupStorage(pdfURL: url)
            self.markupError = markupError
            super.init()
            toolPicker.selectedTool = defaultMarkupTool

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(saveBeforeAppResignsActive),
                name: UIApplication.willResignActiveNotification,
                object: nil
            )
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        func teardown() {
            saveVisibleDrawings()
            hideToolPicker()
            canvasesByPage.values.forEach { toolPicker.removeObserver($0) }
            pendingSavesByCanvas.values.forEach { $0.cancel() }
            pendingSavesByCanvas.removeAll()
        }

        @objc private func saveBeforeAppResignsActive() {
            saveVisibleDrawings()
        }

        func reset(for url: URL) {
            saveVisibleDrawings()
            hideToolPicker()
            pendingSavesByCanvas.values.forEach { $0.cancel() }
            pendingSavesByCanvas.removeAll()
            canvasesByPage.removeAll()
            pageIndexesByCanvas.removeAll()
            self.url = url
            storage = PDFMarkupStorage(pdfURL: url)
        }

        func configure(pdfView: PDFView, isMarkupActive: Bool) {
            self.pdfView = pdfView
            pdfView.isInMarkupMode = isMarkupActive

            guard self.isMarkupActive != isMarkupActive else {
                canvasesByPage.values.forEach { configureCanvas($0) }
                showToolPicker()
                return
            }

            self.isMarkupActive = isMarkupActive
            pdfView.clearSelection()
            canvasesByPage.values.forEach { configureCanvas($0) }

            if isMarkupActive {
                pdfView.layoutDocumentView()
                showToolPicker()
            } else {
                saveVisibleDrawings()
                hideToolPicker()
            }
        }

        func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> UIView? {
            self.pdfView = view
            let canvas = canvasesByPage[page] ?? makeCanvas(for: page, in: view)
            configureCanvas(canvas)
            return canvas
        }

        func pdfView(_ pdfView: PDFView, willDisplayOverlayView overlayView: UIView, for page: PDFPage) {
            guard let canvas = overlayView as? PKCanvasView else { return }
            configureCanvas(canvas)
            showToolPicker()
        }

        func pdfView(_ pdfView: PDFView, willEndDisplayingOverlayView overlayView: UIView, for page: PDFPage) {
            guard let canvas = overlayView as? PKCanvasView else { return }
            saveDrawing(from: canvas)
        }

        private func makeCanvas(for page: PDFPage, in pdfView: PDFView) -> PKCanvasView {
            let canvas = PDFMarkupCanvasView()
            canvas.backgroundColor = .clear
            canvas.isOpaque = false
            canvas.delegate = self
            canvas.drawingPolicy = .anyInput
            canvas.tool = defaultMarkupTool
            toolPicker.addObserver(canvas)

            if let pageIndex = pageIndex(for: page, in: pdfView.document) {
                pageIndexesByCanvas[ObjectIdentifier(canvas)] = pageIndex
                canvas.drawing = storage.loadDrawing(forPageAt: pageIndex, reportError: reportStorageError)
            }

            canvasesByPage[page] = canvas
            return canvas
        }

        private func configureCanvas(_ canvas: PKCanvasView) {
            canvas.drawingPolicy = .anyInput
            canvas.isUserInteractionEnabled = isMarkupActive
            toolPicker.setVisible(isMarkupActive, forFirstResponder: canvas)

            if !isMarkupActive {
                canvas.resignFirstResponder()
            }
        }

        private func showToolPicker() {
            guard isMarkupActive else { return }

            DispatchQueue.main.async { [weak self] in
                guard let self, let pdfView = self.pdfView, self.isMarkupActive, pdfView.window != nil else { return }
                self.toolPicker.setVisible(true, forFirstResponder: pdfView)
                pdfView.becomeFirstResponder()
            }
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard isMarkupActive else { return }

            let canvasID = ObjectIdentifier(canvasView)
            pendingSavesByCanvas[canvasID]?.cancel()

            let workItem = DispatchWorkItem { [weak self, weak canvasView] in
                guard let self, let canvasView else { return }
                self.saveDrawing(from: canvasView)
            }
            pendingSavesByCanvas[canvasID] = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: workItem)
        }

        private func saveVisibleDrawings() {
            canvasesByPage.values.forEach { saveDrawing(from: $0) }
        }

        private func saveDrawing(from canvas: PKCanvasView) {
            let canvasID = ObjectIdentifier(canvas)
            pendingSavesByCanvas[canvasID]?.cancel()
            pendingSavesByCanvas[canvasID] = nil

            guard let pageIndex = pageIndexesByCanvas[canvasID] else { return }
            storage.save(canvas.drawing, forPageAt: pageIndex, reportError: reportStorageError)
        }

        private func hideToolPicker() {
            if let pdfView {
                toolPicker.setVisible(false, forFirstResponder: pdfView)
                pdfView.resignFirstResponder()
            }

            canvasesByPage.values.forEach { canvas in
                toolPicker.setVisible(false, forFirstResponder: canvas)
                canvas.resignFirstResponder()
            }
        }

        private func pageIndex(for page: PDFPage, in document: PDFDocument?) -> Int? {
            guard let document else { return nil }
            let index = document.index(for: page)
            return index == NSNotFound ? nil : index
        }

        private func reportStorageError(_ message: String) {
            markupError.wrappedValue = PDFMarkupError(message: message)
        }
    }
}

private struct PDFMarkupStorage {
    let pdfURL: URL

    private var directoryURL: URL {
        get throws {
            let applicationSupportDirectory = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let directory = applicationSupportDirectory
                .appendingPathComponent("PDFMarkups", isDirectory: true)
                .appendingPathComponent(pdfURL.lastPathComponent, isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            return directory
        }
    }

    func loadDrawing(forPageAt pageIndex: Int, reportError: (String) -> Void) -> PKDrawing {
        do {
            let fileURL = try drawingURL(forPageAt: pageIndex)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                return PKDrawing()
            }

            let data = try Data(contentsOf: fileURL)
            return try PKDrawing(data: data)
        } catch {
            reportError("Saved markup for this PDF page could not be loaded.")
            return PKDrawing()
        }
    }

    func save(_ drawing: PKDrawing, forPageAt pageIndex: Int, reportError: (String) -> Void) {
        do {
            let fileURL = try drawingURL(forPageAt: pageIndex)

            if drawing.strokes.isEmpty {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try FileManager.default.removeItem(at: fileURL)
                }
                return
            }

            try drawing.dataRepresentation().write(to: fileURL, options: [.atomic])
        } catch {
            reportError("The PDF markup could not be saved.")
        }
    }

    private func drawingURL(forPageAt pageIndex: Int) throws -> URL {
        try directoryURL.appendingPathComponent("page-\(pageIndex).drawing")
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
