//
//  LoopLineTests.swift
//  LoopLineTests
//
//  Created by Dominik de Jesus Moreira on 09.09.26.
//

import SwiftData
import Testing
import UIKit
import XCTest
@testable import LoopLine

final class ProjectPersistenceTests: XCTestCase {
    func testPartialErasingSplitsMarkupStroke() {
        let stroke = PDFMarkupStroke(
            pageIndex: 0,
            points: [PDFMarkupPoint(CGPoint(x: 0, y: 0)), PDFMarkupPoint(CGPoint(x: 100, y: 0))],
            color: PDFMarkupColor(UIColor(red: 1, green: 0.8, blue: 0, alpha: 0.38)),
            width: 10,
            isMarker: true
        )

        let fragments = stroke.erasing(at: CGPoint(x: 50, y: 0), withRadius: 15)

        XCTAssertEqual(fragments.count, 2)
        XCTAssertLessThan(fragments[0].points.last!.cgPoint.x, 50)
        XCTAssertGreaterThan(fragments[1].points.first!.cgPoint.x, 50)
    }

    func testErasingOutsideMarkupKeepsOriginalStroke() {
        let stroke = PDFMarkupStroke(
            pageIndex: 0,
            points: [PDFMarkupPoint(CGPoint(x: 0, y: 0)), PDFMarkupPoint(CGPoint(x: 100, y: 0))],
            color: PDFMarkupColor(UIColor(red: 1, green: 0.8, blue: 0, alpha: 0.38)),
            width: 10,
            isMarker: true
        )

        let fragments = stroke.erasing(at: CGPoint(x: 50, y: 50), withRadius: 10)

        XCTAssertEqual(fragments.first?.id, stroke.id)
    }

    @MainActor
    func testPDFURLRequiresPDFSourceAndExistingFile() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LoopLine-PDF-Resolver-\(UUID().uuidString).pdf")
        try Data().write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let pdfProject = Project(name: "PDF", sourceType: .pdf, sourceFilePath: fileURL.path)
        XCTAssertEqual(ImportedPDFStorage.fileURL(for: pdfProject), fileURL)

        let textProject = Project(name: "Text", sourceType: .text, sourceFilePath: fileURL.path)
        XCTAssertNil(ImportedPDFStorage.fileURL(for: textProject))

        let missingPDFProject = Project(name: "Missing PDF", sourceType: .pdf)
        XCTAssertNil(ImportedPDFStorage.fileURL(for: missingPDFProject))
    }

    @MainActor
    func testNewProjectTitleAndPatternValidation() {
        var draft = NewProjectDraft()
        XCTAssertFalse(draft.isValid)

        draft.name = "   \n"
        draft.setPastedText("Knit one row")
        XCTAssertFalse(draft.isValid)

        draft.name = "  Scarf  "
        XCTAssertTrue(draft.isValid)
        XCTAssertEqual(draft.trimmedName, "Scarf")
    }

    @MainActor
    func testCancelledPickersPreserveFormState() {
        let viewModel = CreateProjectViewModel()
        viewModel.draft.name = "Scarf"
        viewModel.draft.subtitle = "For Alex"

        viewModel.importPDF(from: .failure(CocoaError(.userCancelled)))
        viewModel.importImage(from: nil)

        XCTAssertEqual(viewModel.draft.name, "Scarf")
        XCTAssertEqual(viewModel.draft.subtitle, "For Alex")
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testCancellingTextEditingDoesNotReplaceSavedText() {
        let viewModel = CreateProjectViewModel()
        viewModel.savePatternText("Original pattern")
        viewModel.showTextEditor()

        XCTAssertEqual(viewModel.draft.sourceText, "Original pattern")
        XCTAssertEqual(viewModel.draft.sourceType, .text)
    }

    @MainActor
    func testPatternSourceTransitionsAndRemoval() {
        let viewModel = CreateProjectViewModel()

        viewModel.adoptPDF(path: "pattern.pdf", fileName: "Cable.pdf")
        XCTAssertEqual(viewModel.draft.sourceType, .pdf)
        XCTAssertEqual(viewModel.draft.sourceFileName, "Cable.pdf")

        viewModel.adoptImage(path: "photo.jpg", fileName: "photo.jpg")
        XCTAssertEqual(viewModel.draft.sourceType, .image)
        XCTAssertEqual(viewModel.draft.imageFilePath, "photo.jpg")

        viewModel.savePatternText("Row 1: knit")
        XCTAssertEqual(viewModel.draft.sourceType, .text)
        XCTAssertEqual(viewModel.draft.sourceText, "Row 1: knit")

        viewModel.removeSelectedSource()
        XCTAssertNil(viewModel.draft.sourceType)
        XCTAssertFalse(viewModel.draft.isValid)
    }

    @MainActor
    func testCreateProjectPersistsTrimmedFormAndPattern() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let viewModel = ProjectListViewModel()
        var draft = NewProjectDraft()
        draft.name = "  Cable Hat  "
        draft.subtitle = "  Winter gift  "
        draft.setPastedText("  Row 1: knit  ")

        try viewModel.createProject(from: draft, in: context)

        let savedProject = try XCTUnwrap(try context.fetch(FetchDescriptor<Project>()).first)
        XCTAssertEqual(savedProject.name, "Cable Hat")
        XCTAssertEqual(savedProject.subtitle, "Winter gift")
        XCTAssertEqual(savedProject.sourceType, .text)
        XCTAssertEqual(savedProject.sourceText, "Row 1: knit")
        XCTAssertEqual(savedProject.rows, ["Row 1: knit"])
    }

    @MainActor
    func testFailedPersistenceKeepsDraftAndShowsError() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let listViewModel = ProjectListViewModel()
        let createViewModel = CreateProjectViewModel()
        createViewModel.draft.name = "Scarf"
        createViewModel.draft.subtitle = "Blue"
        createViewModel.savePatternText("Knit every row")

        createViewModel.createProject { draft in
            try listViewModel.createProject(from: draft, in: context) { _ in
                throw TestError.saveFailed
            }
        }

        XCTAssertEqual(createViewModel.draft.name, "Scarf")
        XCTAssertEqual(createViewModel.draft.subtitle, "Blue")
        XCTAssertEqual(createViewModel.draft.sourceText, "Knit every row")
        XCTAssertNotNil(createViewModel.errorMessage)
        XCTAssertFalse(createViewModel.didCreateProject)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Project>()).isEmpty)
    }

    @MainActor
    func testProjectPreservesTrackingValuesAfterSaveAndFetch() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = Project(
            name: "Aran Cable Sweater",
            sourceType: .text,
            currentRow: 12,
            repeatCurrent: 3,
            currentStitch: 48,
            rows: ["Knit the cable pattern."],
            sourceText: "Knit the cable pattern."
        )
        context.insert(project)
        try context.save()

        let freshContext = ModelContext(container)
        let projects = try freshContext.fetch(FetchDescriptor<Project>())

        XCTAssertEqual(projects.count, 1)
        let savedProject = try XCTUnwrap(projects.first)
        XCTAssertEqual(savedProject.id, project.id)
        XCTAssertEqual(savedProject.name, "Aran Cable Sweater")
        XCTAssertEqual(savedProject.sourceType, .text)
        XCTAssertEqual(savedProject.rows, ["Knit the cable pattern."])
        XCTAssertEqual(savedProject.sourceText, "Knit the cable pattern.")
        XCTAssertTrue(savedProject.notes.isEmpty)
        XCTAssertEqual(savedProject.currentRow, 12)
        XCTAssertEqual(savedProject.currentStitch, 48)
        XCTAssertEqual(savedProject.repeatCurrent, 3)
    }

    @MainActor
    func testEditingNotePersistsTextAndRow() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let note = ProjectNote(text: "Original", rowNumber: 2)
        let project = Project(name: "Scarf", sourceType: .text, notes: [note])
        context.insert(project)
        try context.save()

        let draft = NoteDraft(text: "  Updated note  ", rowNumberText: "5")
        ProjectDetailViewModel().updateNote(note, from: draft, in: context)

        let savedNote = try XCTUnwrap(try context.fetch(FetchDescriptor<ProjectNote>()).first)
        XCTAssertEqual(savedNote.text, "Updated note")
        XCTAssertEqual(savedNote.rowNumber, 5)
    }

    @MainActor
    func testDeletingNoteRemovesItFromPersistence() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let note = ProjectNote(text: "Remove me")
        let project = Project(name: "Scarf", sourceType: .text, notes: [note])
        context.insert(project)
        try context.save()

        ProjectDetailViewModel().deleteNote(note, in: context)

        XCTAssertTrue(try context.fetch(FetchDescriptor<ProjectNote>()).isEmpty)
    }

    @MainActor
    func testCounterChangesRecordMetricValueDirectionAndTimestamp() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = Project(name: "Scarf", sourceType: .pdf)
        let viewModel = PDFReadingViewModel()

        viewModel.incrementSelectedMetric(for: project, in: context)

        let change = try XCTUnwrap(project.lastCounterChange)
        XCTAssertEqual(change.metric, .row)
        XCTAssertEqual(change.value, 1)
        XCTAssertEqual(change.direction, .increased)
        XCTAssertNotNil(project.lastCounterChangedAt)
    }

    @MainActor
    func testNewCounterChangeReplacesThePreviousChange() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = Project(name: "Scarf", sourceType: .pdf)
        let viewModel = PDFReadingViewModel()

        viewModel.incrementSelectedMetric(for: project, in: context)
        viewModel.selectMetric(.stitches, for: project, in: context)
        viewModel.incrementSelectedMetric(for: project, in: context)

        let change = try XCTUnwrap(project.lastCounterChange)
        XCTAssertEqual(change.metric, .stitches)
        XCTAssertEqual(change.value, 1)
        XCTAssertEqual(change.direction, .increased)
    }

    @MainActor
    func testIneffectiveDecrementDoesNotReplaceTheLastCounterChange() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = Project(name: "Scarf", sourceType: .pdf)
        let timestamp = Date(timeIntervalSinceReferenceDate: 12_345)
        project.recordLastCounterChange(metric: .repeatCount, value: 2, direction: .decreased, timestamp: timestamp)
        let viewModel = PDFReadingViewModel()

        viewModel.decrementSelectedMetric(for: project, in: context)

        let change = try XCTUnwrap(project.lastCounterChange)
        XCTAssertEqual(change.metric, .repeatCount)
        XCTAssertEqual(change.value, 2)
        XCTAssertEqual(change.direction, .decreased)
        XCTAssertEqual(change.timestamp, timestamp)
    }

    @MainActor
    func testSelectingAnotherMetricDoesNotChangeTheLastCounterChange() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = Project(name: "Scarf", sourceType: .pdf)
        let timestamp = Date(timeIntervalSinceReferenceDate: 12_345)
        project.recordLastCounterChange(metric: .row, value: 4, direction: .increased, timestamp: timestamp)
        let viewModel = PDFReadingViewModel()

        viewModel.selectMetric(.repeatCount, for: project, in: context)

        XCTAssertEqual(viewModel.selectedMetric, .repeatCount)
        XCTAssertEqual(project.lastCounterChange?.metric, .row)
        XCTAssertEqual(project.lastCounterChange?.value, 4)
        XCTAssertEqual(project.lastCounterChange?.timestamp, timestamp)
    }

    @MainActor
    func testDirectRowSelectionRecordsANeutralCounterChange() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = Project(
            name: "Scarf",
            sourceType: .text,
            rows: ["Row 1", "Row 2", "Row 3"]
        )
        let viewModel = ReadingModeViewModel()

        viewModel.selectRow(at: 2, in: project, modelContext: context)

        let change = try XCTUnwrap(project.lastCounterChange)
        XCTAssertEqual(change.metric, .row)
        XCTAssertEqual(change.value, 2)
        XCTAssertEqual(change.direction, .set)
    }

    @MainActor
    func testLastCounterChangePersistsAndProjectsRemainIndependent() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let firstProject = Project(name: "Scarf", sourceType: .text)
        let secondProject = Project(name: "Socks", sourceType: .text)
        firstProject.recordLastCounterChange(metric: .stitches, value: 24, direction: .increased)
        context.insert(firstProject)
        context.insert(secondProject)
        try context.save()

        let freshContext = ModelContext(container)
        let savedProjects = try freshContext.fetch(FetchDescriptor<Project>())
        let savedFirstProject = try XCTUnwrap(savedProjects.first { $0.id == firstProject.id })
        let savedSecondProject = try XCTUnwrap(savedProjects.first { $0.id == secondProject.id })

        XCTAssertEqual(savedFirstProject.lastCounterChange?.metric, .stitches)
        XCTAssertEqual(savedFirstProject.lastCounterChange?.value, 24)
        XCTAssertEqual(savedFirstProject.lastCounterChange?.direction, .increased)
        XCTAssertNotNil(savedFirstProject.lastCounterChange?.timestamp)
        XCTAssertNil(savedSecondProject.lastCounterChange)
    }

    func testLastCounterChangeTimestampUsesTimeTodayAndDateForOlderChanges() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let locale = Locale(identifier: "en_US")
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 18, hour: 17, minute: 48)) ?? .now
        let today = calendar.date(byAdding: .minute, value: -1, to: now) ?? now
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now

        let todayText = LastCounterChangeFormatter.timestampText(for: today, now: now, calendar: calendar, locale: locale)
        let olderText = LastCounterChangeFormatter.timestampText(for: yesterday, now: now, calendar: calendar, locale: locale)

        XCTAssertFalse(todayText.contains("2026"))
        XCTAssertTrue(olderText.contains("2026"))
    }

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Project.self, ProjectNote.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private enum TestError: Error {
        case saveFailed
    }
}

@Suite("PDF Reading State Persistence")
struct PDFReadingStatePersistenceTests {
    @Test @MainActor
    func persistsReadingPositionAndSelectedMetric() throws {
        let container = try ModelContainer(
            for: Project.self, ProjectNote.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let project = Project(name: "Cable Chart", sourceType: .pdf)
        project.lastPDFPageIndex = 4
        project.lastPDFPageVerticalPosition = 0.375
        project.selectedTrackingMetricRawValue = ReadingTrackingMetric.stitches.rawValue
        context.insert(project)
        try context.save()

        let freshContext = ModelContext(container)
        let savedProject = try #require(try freshContext.fetch(FetchDescriptor<Project>()).first)

        #expect(savedProject.lastPDFPageIndex == 4)
        #expect(savedProject.lastPDFPageVerticalPosition == 0.375)
        #expect(savedProject.selectedTrackingMetricRawValue == ReadingTrackingMetric.stitches.rawValue)
    }

    @Test @MainActor
    func fallsBackToRowForAnUnknownSavedMetric() {
        let project = Project(name: "Cable Chart", sourceType: .pdf)
        project.selectedTrackingMetricRawValue = "unknown"
        let viewModel = PDFReadingViewModel()

        viewModel.restoreSelectedMetric(for: project)

        #expect(viewModel.selectedMetric == .row)
    }
}
