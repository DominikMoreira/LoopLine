import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class PDFReadingViewModel {
    var selectedMetric: ReadingTrackingMetric = .row
    var isMarkupActive = false
    var markupError: PDFMarkupError?

    func pdfURL(for project: Project) -> URL? {
        ImportedPDFStorage.fileURL(for: project)
    }

    func restoreSelectedMetric(for project: Project) {
        selectedMetric = ReadingTrackingMetric(rawValue: project.selectedTrackingMetricRawValue) ?? .row
    }

    func selectMetric(_ metric: ReadingTrackingMetric, for project: Project, in modelContext: ModelContext) {
        selectedMetric = metric
        guard project.selectedTrackingMetricRawValue != metric.rawValue else { return }

        project.selectedTrackingMetricRawValue = metric.rawValue
        save(modelContext)
    }

    func restoreReadingPosition(for project: Project) -> PDFReadingPosition {
        PDFReadingPosition(
            pageIndex: max(project.lastPDFPageIndex, 0),
            verticalPosition: min(max(project.lastPDFPageVerticalPosition, 0), 1)
        )
    }

    func saveReadingPosition(
        _ position: PDFReadingPosition,
        for project: Project,
        in modelContext: ModelContext
    ) {
        guard project.lastPDFPageIndex != position.pageIndex ||
                project.lastPDFPageVerticalPosition != position.verticalPosition else {
            return
        }

        project.lastPDFPageIndex = position.pageIndex
        project.lastPDFPageVerticalPosition = position.verticalPosition
        save(modelContext)
    }

    func selectedMetricValue(for project: Project) -> Int {
        switch selectedMetric {
        case .row:
            max(project.currentRow, 0)
        case .stitches:
            max(project.currentStitch, 0)
        case .repeatCount:
            max(project.repeatCurrent, 0)
        }
    }

    func canDecreaseSelectedMetric(for project: Project) -> Bool {
        selectedMetricValue(for: project) > 0
    }

    func incrementSelectedMetric(for project: Project, in modelContext: ModelContext) {
        switch selectedMetric {
        case .row:
            project.currentRow += 1
        case .stitches:
            project.currentStitch += 1
        case .repeatCount:
            project.repeatCurrent += 1
        }

        project.recordLastCounterChange(
            metric: selectedMetric,
            value: selectedMetricValue(for: project),
            direction: .increased
        )
        save(modelContext)
    }

    func decrementSelectedMetric(for project: Project, in modelContext: ModelContext) {
        guard canDecreaseSelectedMetric(for: project) else { return }

        switch selectedMetric {
        case .row:
            project.currentRow = max(project.currentRow - 1, 0)
        case .stitches:
            project.currentStitch = max(project.currentStitch - 1, 0)
        case .repeatCount:
            project.repeatCurrent = max(project.repeatCurrent - 1, 0)
        }

        project.recordLastCounterChange(
            metric: selectedMetric,
            value: selectedMetricValue(for: project),
            direction: .decreased
        )
        save(modelContext)
    }

    func normalizeTrackingValues(for project: Project, in modelContext: ModelContext) {
        let normalizedRow = max(project.currentRow, 0)
        let normalizedStitch = max(project.currentStitch, 0)
        let normalizedRepeat = max(project.repeatCurrent, 0)
        guard normalizedRow != project.currentRow || normalizedStitch != project.currentStitch || normalizedRepeat != project.repeatCurrent else {
            return
        }

        project.currentRow = normalizedRow
        project.currentStitch = normalizedStitch
        project.repeatCurrent = normalizedRepeat
        save(modelContext)
    }

    var markupHintText: String {
        isMarkupActive
        ? String(localized: "Choose a tool from the palette, then draw with finger or Apple Pencil")
        : String(localized: "Pinch to zoom - drag to pan")
    }

    private func save(_ modelContext: ModelContext) {
        try? modelContext.save()
    }
}

struct PDFReadingPosition: Equatable {
    let pageIndex: Int
    let verticalPosition: Double
}

struct PDFMarkupError: Identifiable {
    let id = UUID()
    let message: String
}
