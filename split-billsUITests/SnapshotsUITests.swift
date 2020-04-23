//
//  SnapshotsUITests.swift
//  split-billsUITests
//
//  Created by Carlos DeElias on 23/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import XCTest

class SnapshotsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        setupSnapshot(app)
        app.launchEnvironment = ["UI_TESTING": "true", "launch_option": "snapshots"]
        app.launch()
    }

    func testHomeSnapshot() throws {
        snapshot("01HomeScreen")
    }

    func testSplitDetailsSnapshot() throws {
        XCUIApplication().tables.cells.buttons["Friday night dinner"].tap()
        snapshot("02SplitDetail")
    }

    func testNewExpenseSnapshot() throws {
        let tablesQuery = app.tables
        tablesQuery.cells.buttons["Friday night dinner"].tap()
        app.buttons["plus_icon"].tap()

        let whatWasForTextField = tablesQuery.textFields["What was for?"]
        whatWasForTextField.tap()
        whatWasForTextField.typeText("Coffee")
        tablesQuery.buttons["Payer"].tap()
        tablesQuery.buttons["Issac"].tap()

        let amountTextField = tablesQuery.textFields["amountTextField"]
        amountTextField.tap()
        amountTextField.typeText("14")
        amountTextField.typeText("\n")

        tablesQuery.switches["Equally between everyone"].tap()
        tablesQuery.buttons["Alice"].tap()
        snapshot("03NewExpense")
    }
}
