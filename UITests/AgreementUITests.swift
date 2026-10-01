import XCTest

final class AgreementUITests: XCTestCase {
    func testDraftRecoveryAndCompletePreview() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launch()
        app.buttons["Create Document"].tap()
        XCTAssertTrue(app.staticTexts["Client & project"].waitForExistence(timeout: 10))
        func fill(_ label: String, _ text: String) {
            let field = app.textFields[label]
            if !field.isHittable { app.swipeUp() }
            XCTAssertTrue(field.waitForExistence(timeout: 5), "Missing \(label)")
            field.tap(); field.typeText(text)
        }
        let clientName = "UI Client " + String(UUID().uuidString.prefix(6))
        fill("Client name", clientName)
        fill("Address", "Gomti Nagar Lucknow")
        fill("Mobile", "9453919659")
        fill("Subject", "Residence construction")
        app.buttons["Save Draft"].tap()
        XCTAssertTrue(app.staticTexts["Draft saved"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()
        app.terminate(); app.launch()
        app.buttons["Saved Documents"].tap()
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "savedDocument-")).firstMatch.tap()
        XCTAssertTrue(app.textFields["Client name"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["Client name"].value as? String, clientName)
        app.buttons["Next"].tap()
        for _ in 0..<3 { if !app.buttons["addNewTitle"].isHittable { app.swipeUp() } }
        app.buttons["addNewTitle"].tap()
        XCTAssertFalse(app.buttons["saveNewTitle"].isEnabled)
        fill("newWorkTitle", "Landscaping")
        app.buttons["saveNewTitle"].tap()
        // Scope, A–J, then the newly added specification screen.
        for _ in 0..<11 { app.buttons["Next"].tap() }
        XCTAssertTrue(app.staticTexts["Landscaping"].waitForExistence(timeout: 5))
        fill("Content", "Garden planting and site landscaping.")
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["K. Fees & measurements"].waitForExistence(timeout: 5))
        fill("Area (sq ft)", "1000")
        for _ in 0..<5 { app.buttons["Next"].tap() }
        XCTAssertTrue(app.staticTexts["Review agreement"].waitForExistence(timeout: 5))
        app.buttons["Generate Preview"].tap()
        XCTAssertTrue(app.navigationBars["PDF Preview"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["Download PDF"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Page 1 of ")).firstMatch.exists)
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = "PDF Preview"; attachment.lifetime = .keepAlways; add(attachment)
        app.buttons["Next page"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Page 2 of ")).firstMatch.waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        app.buttons["Close"].tap()
    }
}
