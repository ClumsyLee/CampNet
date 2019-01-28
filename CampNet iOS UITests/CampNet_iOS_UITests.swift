//
//  CampNet_iOS_UITests.swift
//  CampNet iOS UITests
//
//  Created by Thomas Lee on 2017/8/28.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import XCTest

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

        sleep(2)
        app.navigationBars.buttons["accounts"].tap()
        snapshot("4-accounts")

        sleep(2)
        app.cells.staticTexts["lisihan13"].tap()
        snapshot("1-overview")

        sleep(2)
        app.buttons["devices"].tap()
        snapshot("5-devices")

        sleep(2)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(2)
        app.navigationBars.buttons["accounts"].tap()
        sleep(2)
        app.cells.staticTexts["liws13"].tap()
        snapshot("2-overview")

        sleep(2)
        app.navigationBars.buttons["settings"].tap()
        snapshot("3-settings")
    }
}
