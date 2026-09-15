//
//  LoopLineTests.swift
//  LoopLineTests
//
//  Created by Dominik de Jesus Moreira on 09.09.26.
//

import SwiftData
import XCTest
@testable import LoopLine

final class ProjectPersistenceTests: XCTestCase {
    @MainActor
    func testProjectPreservesTrackingValuesAfterSaveAndFetch() throws {
        let container = try ModelContainer(
            for: Project.self, ProjectNote.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
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
}
