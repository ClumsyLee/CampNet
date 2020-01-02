//
//  CampNet_iOS_UITests.swift
//  CampNet iOS UITests
//
//  Created by Thomas Lee on 2017/8/28.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import XCTest

// To fix the "Failed to scroll to visible" problem. See
// https://stackoverflow.com/questions/33422681/xcode-ui-test-ui-testing-failure-failed-to-scroll-to-visible-by-ax-action/39898733
// for the details.
extension XCUIElement {
    func forceTapElement() {
        if self.isHittable {
            self.tap()
        }
        else {
            let coordinate: XCUICoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.0))
            coordinate.tap()
        }
    }
}

class CampNet_iOS_UITests: XCTestCase {

    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each
        //   test method.
        let app = XCUIApplication()
        app.launchEnvironment["UITest"] = "1"
        setupSnapshot(app)
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your
        //   tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testTakeScreenshots() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        let app = XCUIApplication()

        app.navigationBars.buttons["accounts"].tap()
        snapshot("4-accounts")

        app.cells.staticTexts["lisihan13 (李思涵)"].tap()
        snapshot("1-overview")

        app.buttons["devices"].tap()
        snapshot("5-devices")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons["accounts"].tap()
        // On some devices, there are two back buttons.
        var addButton = app.navigationBars.buttons.element(boundBy: 2)
        if !addButton.exists {
            addButton = app.navigationBars.buttons.element(boundBy: 1)
        }
        addButton.tap()
        snapshot("2-configurations")

        app.navigationBars.buttons.element(boundBy: 0).forceTapElement()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons["settings"].tap()
        snapshot("3-settings")
    }
}
