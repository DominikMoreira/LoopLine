import XCTest

final class ReadingModeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testUserCanOpenReadingModeFromPDFProject() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-uiTesting")
        app.launch()

        let project = app.buttons["uiTestPDFProject"]
        XCTAssertTrue(project.waitForExistence(timeout: 5))
        project.tap()

        let openReadingModeButton = app.buttons["openReadingModeButton"]
        XCTAssertTrue(openReadingModeButton.waitForExistence(timeout: 5))
        openReadingModeButton.tap()

        let pdfReadingMode = app.descendants(matching: .any)["pdfReadingMode"]
        XCTAssertTrue(pdfReadingMode.waitForExistence(timeout: 5))
    }
}
