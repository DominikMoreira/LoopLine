//
//  LoopLineTests.swift
//  LoopLineTests
//
//  Created by Dominik de Jesus Moreira on 09.09.26.
//

import SwiftData
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
