//
//  mad_applicationUITests.swift
//  mad_applicationUITests
//
//  Created by Павел on 13.12.2025.
//

import XCTest

final class mad_applicationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testHappyPathWithMockResponse() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["UITEST_MOCK": "1"]
        app.launch()

        let modelPicker = app.buttons["modelPicker"]
        XCTAssertTrue(modelPicker.waitForExistence(timeout: 10))
        XCTAssertTrue(waitForLabelNotEqual(modelPicker, notEquals: "Выбрать модель", timeout: 10))

        let promptEditor = app.textViews["promptEditor"]
        XCTAssertTrue(promptEditor.waitForExistence(timeout: 10))
        promptEditor.tap()
        promptEditor.typeText("Привет!")

        let sendButton = app.buttons["sendPromptButton"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 10))
        sendButton.tap()

        let responseText = app.staticTexts["responseText"]
        XCTAssertTrue(responseText.waitForExistence(timeout: 10))
        XCTAssertTrue(waitForLabelContains(responseText, contains: "Mock response", timeout: 10))
    }

    @MainActor
    func testValidationErrorWhenPromptEmpty() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["UITEST_MOCK": "1"]
        app.launch()

        let modelPicker = app.buttons["modelPicker"]
        XCTAssertTrue(modelPicker.waitForExistence(timeout: 10))
        XCTAssertTrue(waitForLabelNotEqual(modelPicker, notEquals: "Выбрать модель", timeout: 10))

        let sendButton = app.buttons["sendPromptButton"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 10))
        sendButton.tap()

        let errorText = app.staticTexts["errorText"]
        XCTAssertTrue(errorText.waitForExistence(timeout: 10))
        XCTAssertEqual(errorText.label, "Введите промпт")
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    private func waitForLabel(_ element: XCUIElement, equals value: String, timeout: TimeInterval = 3) -> Bool {
        let predicate = NSPredicate(format: "label == %@", value)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let waiter = XCTWaiter()
        return waiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    private func waitForLabelContains(_ element: XCUIElement, contains value: String, timeout: TimeInterval = 3) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", value)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let waiter = XCTWaiter()
        return waiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    private func waitForLabelNotEqual(_ element: XCUIElement, notEquals value: String, timeout: TimeInterval = 3) -> Bool {
        let predicate = NSPredicate(format: "label != %@", value)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let waiter = XCTWaiter()
        return waiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
