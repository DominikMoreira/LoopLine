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

    @MainActor
    func testUserCanOpenReadingModeFromPDFPreview() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-uiTesting")
        app.launch()

        let project = app.buttons["uiTestPDFProject"]
        XCTAssertTrue(project.waitForExistence(timeout: 5))
        project.tap()

        let pdfPreview = app.buttons["openPDFPreview"]
        XCTAssertTrue(pdfPreview.waitForExistence(timeout: 5))
        pdfPreview.tap()

        let pdfReadingMode = app.descendants(matching: .any)["pdfReadingMode"]
        XCTAssertTrue(pdfReadingMode.waitForExistence(timeout: 5))
    }

    @MainActor
    func testUserCanOpenReadingModeFromImagePreview() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-uiTesting")
        app.launch()

        let project = app.buttons["uiTestImageProject"]
        XCTAssertTrue(project.waitForExistence(timeout: 5))
        project.tap()

        let imagePreview = app.buttons["openImagePreview"]
        XCTAssertTrue(imagePreview.waitForExistence(timeout: 5))
        imagePreview.tap()

        let imageReadingMode = app.descendants(matching: .any)["imageReadingMode"]
        XCTAssertTrue(imageReadingMode.waitForExistence(timeout: 5))
    }
}
