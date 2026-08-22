import Observation
import PDFKit
import PencilKit
import SwiftData
import SwiftUI

struct PDFReadingView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project
    @State private var viewModel = PDFReadingViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        Group {
            if let pdfURL = viewModel.pdfURL(for: project) {
                VStack(spacing: 0) {
                    trackingControls
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 10)

                    PDFKitView(
                        url: pdfURL,
                        isMarkupActive: viewModel.isMarkupActive,
                        markupError: $viewModel.markupError
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(viewModel.isMarkupActive ? .yellow.opacity(0.75) : LoopLineTheme.readingStroke, lineWidth: viewModel.isMarkupActive ? 2 : 1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    Text(viewModel.markupHintText)
                        .font(.caption.monospaced())
                        .foregroundStyle(LoopLineTheme.readingSecondaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(LoopLineTheme.mediaHintBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(.bottom, 16)
                }
                .background(LoopLineTheme.readingBackground.ignoresSafeArea())
            } else {
                VStack(spacing: 0) {
                    trackingControls
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 10)

                    ContentUnavailableView(
                        "PDF Unavailable",
                        systemImage: "doc.richtext",
                        description: Text("The imported PDF could not be found.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .background(LoopLineTheme.readingBackground.ignoresSafeArea())
            }
        }
        .navigationTitle("Reading Mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(LoopLineTheme.readingBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            Button {
                viewModel.isMarkupActive.toggle()
            } label: {
                Label("Markup", systemImage: viewModel.isMarkupActive ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle")
            }
            .accessibilityLabel(viewModel.isMarkupActive ? "Turn Markup Off" : "Turn Markup On")
        }
        .alert(item: $viewModel.markupError) { error in
            Alert(
                title: Text("Markup Not Saved"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            viewModel.normalizeTrackingValues(for: project, in: modelContext)
        }
    }

    private var trackingControls: some View {
        HStack(spacing: 16) {
            Menu {
                ForEach(ReadingTrackingMetric.allCases) { metric in
                    Button(metric.title) {
                        viewModel.selectedMetric = metric
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(viewModel.selectedMetric.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(LoopLineTheme.readingPrimaryText)
                .frame(minWidth: 92, alignment: .leading)
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(LoopLineTheme.readingControlFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .accessibilityLabel("Tracking metric")
            .accessibilityValue(viewModel.selectedMetric.title)

            Spacer(minLength: 0)

            Button {
                viewModel.decrementSelectedMetric(for: project, in: modelContext)
            } label: {
                Image(systemName: "minus")
            }
            .buttonStyle(LoopLineIconButtonStyle(
                size: 48,
                foregroundColor: LoopLineTheme.readingPrimaryText,
                backgroundColor: LoopLineTheme.readingControlFill
            ))
            .disabled(!viewModel.canDecreaseSelectedMetric(for: project))
            .opacity(viewModel.canDecreaseSelectedMetric(for: project) ? 1 : 0.38)
            .accessibilityLabel("Decrease \(viewModel.selectedMetric.title)")

            Text(String(viewModel.selectedMetricValue(for: project)))
                .font(.system(size: 34, weight: .bold).monospacedDigit())
                .foregroundStyle(LoopLineTheme.readingPrimaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(minWidth: 70)
                .accessibilityLabel("\(viewModel.selectedMetric.title) \(viewModel.selectedMetricValue(for: project))")

            Button {
                viewModel.incrementSelectedMetric(for: project, in: modelContext)
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(LoopLineIconButtonStyle(
                size: 48,
                foregroundColor: LoopLineTheme.primaryActionForeground,
                backgroundColor: LoopLineTheme.primaryActionBackground
            ))
            .accessibilityLabel("Increase \(viewModel.selectedMetric.title)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(LoopLineTheme.readingPanel, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(LoopLineTheme.readingStroke, lineWidth: 1)
        }
    }
}

private final class PDFMarkupPDFView: PDFView {
    var isMarkupModeActive = false {
        didSet {
            configurePDFNavigationForMarkup()
        }
    }

    private var originalMinimumTouchesByPan = [ObjectIdentifier: Int]()

    override var canBecomeFirstResponder: Bool {
        true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        configurePDFNavigationForMarkup()
    }

    func configurePDFNavigationForMarkup() {
        configurePDFNavigationForMarkup(in: self)
    }

    private func configurePDFNavigationForMarkup(in view: UIView) {
        if let scrollView = view as? UIScrollView {
            let panGesture = scrollView.panGestureRecognizer
            let gestureID = ObjectIdentifier(panGesture)

            if originalMinimumTouchesByPan[gestureID] == nil {
                originalMinimumTouchesByPan[gestureID] = panGesture.minimumNumberOfTouches
            }

            if isMarkupModeActive {
                panGesture.minimumNumberOfTouches = max(panGesture.minimumNumberOfTouches, 2)
            } else if let originalMinimumTouches = originalMinimumTouchesByPan[gestureID] {
                panGesture.minimumNumberOfTouches = originalMinimumTouches
            }
        }

        view.subviews.forEach { configurePDFNavigationForMarkup(in: $0) }
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

    final class Coordinator: NSObject, UIGestureRecognizerDelegate, PKToolPickerObserver {
        var url: URL

        private var isMarkupActive = false
        private var markupError: Binding<PDFMarkupError?>
        private let toolPicker = PKToolPicker()
        private let defaultMarkupTool = PKInkingTool(.marker, color: UIColor.systemYellow.withAlphaComponent(0.38), width: 14)
        private var currentTool: any PKTool
        private weak var pdfView: PDFView?
        private var markupGesture: UIPanGestureRecognizer?
        private var activeAnnotation: PDFMarkupAnnotation?
        private var activeStroke: PDFMarkupStroke?
        private var activePage: PDFPage?
        private var saveWorkItem: DispatchWorkItem?
        private var markupStorage: PDFMarkupStorage
        private var storedStrokesByPage = [Int: [PDFMarkupStroke]]()
        private var annotationsByStrokeID = [UUID: PDFMarkupAnnotation]()
        private var hasLoadedStoredMarkups = false

        init(url: URL, markupError: Binding<PDFMarkupError?>) {
            self.url = url
            self.markupError = markupError
            self.currentTool = defaultMarkupTool
            self.markupStorage = PDFMarkupStorage(pdfURL: url)
            super.init()
            toolPicker.selectedTool = defaultMarkupTool
            toolPicker.addObserver(self)

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(saveBeforeAppResignsActive),
                name: UIApplication.willResignActiveNotification,
                object: nil
            )
        }

        deinit {
            toolPicker.removeObserver(self)
            NotificationCenter.default.removeObserver(self)
        }

        func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {
            currentTool = toolPicker.selectedTool
        }

        func toolPickerSelectedToolItemDidChange(_ toolPicker: PKToolPicker) {
            currentTool = toolPicker.selectedTool
        }

        func teardown() {
            finishActiveMarkup()
            saveStoredMarkups()
            saveWorkItem?.cancel()
            hideToolPicker()
            if let markupGesture, let pdfView = markupGesture.view {
                pdfView.removeGestureRecognizer(markupGesture)
            }
            markupGesture = nil
            (pdfView as? PDFMarkupPDFView)?.isMarkupModeActive = false
            pdfView?.isInMarkupMode = false
        }

        @objc private func saveBeforeAppResignsActive() {
            finishActiveMarkup()
            saveStoredMarkups()
        }

        func reset(for url: URL) {
            finishActiveMarkup()
            saveStoredMarkups()
            saveWorkItem?.cancel()
            hideToolPicker()
            removeRenderedMarkups()
            self.url = url
            markupStorage = PDFMarkupStorage(pdfURL: url)
            storedStrokesByPage.removeAll()
            hasLoadedStoredMarkups = false
        }

        func configure(pdfView: PDFView, isMarkupActive: Bool) {
            self.pdfView = pdfView
            installMarkupGestureIfNeeded(on: pdfView)
            loadStoredMarkupsIfNeeded(in: pdfView)
            pdfView.isInMarkupMode = isMarkupActive
            (pdfView as? PDFMarkupPDFView)?.isMarkupModeActive = isMarkupActive
            markupGesture?.isEnabled = isMarkupActive

            guard self.isMarkupActive != isMarkupActive else {
                if isMarkupActive {
                    showToolPicker()
                }
                return
            }

            self.isMarkupActive = isMarkupActive
            pdfView.clearSelection()

            if isMarkupActive {
                showToolPicker()
            } else {
                finishActiveMarkup()
                saveStoredMarkups()
                hideToolPicker()
            }
        }

        private func installMarkupGestureIfNeeded(on pdfView: PDFView) {
            guard markupGesture == nil else { return }

            let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleMarkupGesture(_:)))
            gesture.minimumNumberOfTouches = 1
            gesture.maximumNumberOfTouches = 1
            gesture.cancelsTouchesInView = true
            gesture.delegate = self
            gesture.isEnabled = isMarkupActive
            pdfView.addGestureRecognizer(gesture)
            markupGesture = gesture
        }

        @objc private func handleMarkupGesture(_ gesture: UIPanGestureRecognizer) {
            guard isMarkupActive, let pdfView else { return }

            let viewPoint = gesture.location(in: pdfView)
            guard let page = pdfView.page(for: viewPoint, nearest: true) else {
                finishActiveMarkup()
                return
            }

            let pagePoint = pdfView.convert(viewPoint, to: page)

            switch gesture.state {
            case .began:
                beginMarkup(on: page, at: pagePoint)
            case .changed:
                continueMarkup(on: page, at: pagePoint)
            case .ended:
                continueMarkup(on: page, at: pagePoint)
                finishActiveMarkup()
                scheduleMarkupSave()
            case .cancelled, .failed:
                finishActiveMarkup()
            default:
                break
            }
        }

        private func beginMarkup(on page: PDFPage, at point: CGPoint) {
            if isEraserSelected {
                removeMarkup(on: page, near: point)
                return
            }

            guard let pageIndex = pageIndex(for: page) else { return }

            let stroke = PDFMarkupStroke(
                pageIndex: pageIndex,
                points: [PDFMarkupPoint(point)],
                color: PDFMarkupColor(selectedInkColor),
                width: Double(selectedLineWidth),
                isMarker: isMarkerSelected
            )
            let annotation = PDFMarkupAnnotation(stroke: stroke, pageBounds: page.bounds(for: .cropBox))
            page.addAnnotation(annotation)

            activePage = page
            activeStroke = stroke
            activeAnnotation = annotation
            notifyMarkupChanged(on: page)
        }

        private func continueMarkup(on page: PDFPage, at point: CGPoint) {
            if isEraserSelected {
                removeMarkup(on: page, near: point)
                return
            }

            guard page === activePage, var stroke = activeStroke, let annotation = activeAnnotation else {
                beginMarkup(on: page, at: point)
                return
            }

            stroke.points.append(PDFMarkupPoint(point))
            activeStroke = stroke
            annotation.stroke = stroke
            refresh(annotation, on: page)
        }

        private func refresh(_ annotation: PDFAnnotation, on page: PDFPage) {
            page.removeAnnotation(annotation)
            page.addAnnotation(annotation)
            notifyMarkupChanged(on: page)
        }

        private func finishActiveMarkup() {
            if let stroke = activeStroke, stroke.points.count > 1, let annotation = activeAnnotation {
                storedStrokesByPage[stroke.pageIndex, default: []].append(stroke)
                annotationsByStrokeID[stroke.id] = annotation
            } else if let activeAnnotation, let activePage {
                activePage.removeAnnotation(activeAnnotation)
            }

            activeAnnotation = nil
            activeStroke = nil
            activePage = nil
        }

        private var selectedInkColor: UIColor {
            guard let tool = currentTool as? PKInkingTool else {
                return UIColor.systemYellow.withAlphaComponent(0.38)
            }

            return tool.color
        }

        private var selectedLineWidth: CGFloat {
            guard let tool = currentTool as? PKInkingTool else {
                return 14
            }
            return max(tool.width, 1)
        }

        private var isMarkerSelected: Bool {
            guard let tool = currentTool as? PKInkingTool else { return true }
            return tool.inkType == .marker
        }

        private var isEraserSelected: Bool {
            currentTool is PKEraserTool
        }

        private func removeMarkup(on page: PDFPage, near point: CGPoint) {
            guard let pageIndex = pageIndex(for: page),
                  let pageStrokes = storedStrokesByPage[pageIndex] else {
                return
            }

            let removalDistance = max(selectedLineWidth, 18)
            let strokeIDsToRemove = pageStrokes
                .filter { $0.contains(point, within: removalDistance) }
                .map(\.id)

            guard !strokeIDsToRemove.isEmpty else { return }

            storedStrokesByPage[pageIndex] = pageStrokes.filter { !strokeIDsToRemove.contains($0.id) }
            strokeIDsToRemove.forEach { strokeID in
                if let annotation = annotationsByStrokeID[strokeID] {
                    annotation.shouldDisplay = false
                    page.removeAnnotation(annotation)
                    annotationsByStrokeID[strokeID] = nil
                }
            }
            notifyMarkupChanged(on: page)
            scheduleMarkupSave()
        }

        private func loadStoredMarkupsIfNeeded(in pdfView: PDFView) {
            guard !hasLoadedStoredMarkups, let document = pdfView.document else { return }

            do {
                let strokes = try markupStorage.load()
                storedStrokesByPage = Dictionary(grouping: strokes, by: \.pageIndex)

                for stroke in strokes {
                    guard let page = document.page(at: stroke.pageIndex) else { continue }
                    let annotation = PDFMarkupAnnotation(stroke: stroke, pageBounds: page.bounds(for: .cropBox))
                    page.addAnnotation(annotation)
                    annotationsByStrokeID[stroke.id] = annotation
                }

                hasLoadedStoredMarkups = true
                pdfView.setNeedsDisplay()
            } catch {
                markupError.wrappedValue = PDFMarkupError(message: "The PDF markup could not be loaded.")
            }
        }

        private func removeRenderedMarkups() {
            guard let document = pdfView?.document else {
                annotationsByStrokeID.removeAll()
                return
            }

            for annotation in annotationsByStrokeID.values {
                annotation.page?.removeAnnotation(annotation)
            }

            for pageIndex in 0..<document.pageCount {
                guard let page = document.page(at: pageIndex) else { continue }
                page.annotations
                    .compactMap { $0 as? PDFMarkupAnnotation }
                    .forEach(page.removeAnnotation)
            }

            annotationsByStrokeID.removeAll()
        }

        private func pageIndex(for page: PDFPage) -> Int? {
            pdfView?.document?.index(for: page)
        }

        private func notifyMarkupChanged(on page: PDFPage) {
            guard let pdfView else { return }

            pdfView.annotationsChanged(on: page)
            let pageRect = pdfView.convert(page.bounds(for: .cropBox), from: page)
            pdfView.setNeedsDisplay(pageRect)
        }

        private func showToolPicker() {
            guard isMarkupActive else { return }

            DispatchQueue.main.async { [weak self] in
                guard let self, let pdfView = self.pdfView, self.isMarkupActive, pdfView.window != nil else { return }
                self.currentTool = self.toolPicker.selectedTool
                self.toolPicker.setVisible(true, forFirstResponder: pdfView)
                pdfView.becomeFirstResponder()
            }
        }

        private func hideToolPicker() {
            guard let pdfView else { return }
            toolPicker.setVisible(false, forFirstResponder: pdfView)
            pdfView.resignFirstResponder()
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            isMarkupActive && touch.type != .indirectPointer
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            false
        }

        private func scheduleMarkupSave() {
            saveWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.saveStoredMarkups()
            }
            saveWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: workItem)
        }

        private func saveStoredMarkups() {
            saveWorkItem?.cancel()
            saveWorkItem = nil

            do {
                let strokes = storedStrokesByPage.values.flatMap { $0 }
                try markupStorage.save(strokes)
            } catch {
                markupError.wrappedValue = PDFMarkupError(message: "The PDF markup could not be saved.")
            }
        }
    }
}

private final class PDFMarkupAnnotation: PDFAnnotation {
    var stroke: PDFMarkupStroke

    init(stroke: PDFMarkupStroke, pageBounds: CGRect) {
        self.stroke = stroke
        super.init(bounds: pageBounds, forType: .stamp, withProperties: nil)
        contents = "LoopLine markup"
        shouldDisplay = true
        shouldPrint = false
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        guard stroke.points.count > 1 else { return }

        context.saveGState()
        context.setShouldAntialias(true)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setLineWidth(CGFloat(stroke.width))
        context.setStrokeColor(stroke.color.uiColor.cgColor)
        context.setBlendMode(stroke.isMarker ? .multiply : .normal)

        let path = CGMutablePath()
        path.move(to: stroke.points[0].cgPoint)
        for point in stroke.points.dropFirst() {
            path.addLine(to: point.cgPoint)
        }

        context.addPath(path)
        context.strokePath()
        context.restoreGState()
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
