//
//  NewExpenseViewModelTests.swift
//  split-bills-tests
//
//  Created by Carlos Miguel de Elias on 18/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import XCTest
@testable import split_bills
import Combine

final class NewExpenseViewModelTests: XCTestCase {

    final class MockRequester: EmptyDataMock {
        var onCreate: ((DataRequesting.ExpenseData) -> Void)?

        override func createExpense(splitId: SplitId, expenseData: ExpenseData) -> AnyPublisher<Void, Never> {
            self.onCreate?(expenseData)
            return Empty().eraseToAnyPublisher()
        }
    }

    var mock: MockRequester!
    var viewModel: NewExpenseViewModel!

    private var bag = Set<AnyCancellable>()

    override func setUpWithError() throws {
        super.setUp()

        mock = MockRequester()
        viewModel = NewExpenseViewModel(splitId: 0, datasource: mock)
        viewModel.send(event: .onAppear)
    }

    func testViewModelStateLoaded() {
        let expectation = XCTestExpectation(description: "split details loaded")

        viewModel.$state.sink { state in
            guard case .loaded = state else { return }
            expectation.fulfill()
        }.store(in: &bag)

        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(viewModel.state == .loaded(0, ExpenseEditModel(participants: DisplayModelMocks.participants)))
    }

    func testCreateExpenseSplitEqually() {
        RunLoop.main.run(mode: .default, before: .distantPast)
        viewModel.send(event: .onNameChange("Expense 1"))
        viewModel.send(event: .onPayerChange(1))
        viewModel.send(event: .onAmountChange("60"))

        let expectation = XCTestExpectation(description: "expense created")

        var expenseData: DataRequesting.ExpenseData?
        mock.onCreate = { result in
            expenseData = result
            expectation.fulfill()
        }

        viewModel.send(event: .onSaveExpense)
        wait(for: [expectation], timeout: 1)

        XCTAssertNotNil(expenseData)
        XCTAssertEqual(expenseData!.name, "Expense 1")
        XCTAssertEqual(expenseData!.payerName, "User 2")
        XCTAssertEqual(expenseData!.amount, 60.0)
        XCTAssertEqual(expenseData!.expenseTypeIndex, 0)

        XCTAssertEqual(expenseData!.weights[0].name, DisplayModelMocks.participant1.name)
        XCTAssertEqual(expenseData!.weights[0].weight, 0.25)
        XCTAssertEqual(expenseData!.weights[1].name, DisplayModelMocks.participant2.name)
        XCTAssertEqual(expenseData!.weights[1].weight, 0.25)
        XCTAssertEqual(expenseData!.weights[2].name, DisplayModelMocks.participant3.name)
        XCTAssertEqual(expenseData!.weights[2].weight, 0.25)
        XCTAssertEqual(expenseData!.weights[3].name, DisplayModelMocks.participant4.name)
        XCTAssertEqual(expenseData!.weights[3].weight, 0.25)
    }

    func testCreateExpenseSplitCustom() {
        RunLoop.main.run(mode: .default, before: .distantPast)
        viewModel.send(event: .onNameChange("Expense 2"))
        viewModel.send(event: .onPayerChange(2))
        viewModel.send(event: .onAmountChange("90"))
        viewModel.send(event: .onSplitEquallyChange(false))
        viewModel.send(event: .onExpenseTypeSelectionChange(3, isSelected: false))

        let expectation = XCTestExpectation(description: "expense created")

        var expenseData: DataRequesting.ExpenseData?
        mock.onCreate = { result in
            expenseData = result
            expectation.fulfill()
        }

        viewModel.send(event: .onSaveExpense)
        wait(for: [expectation], timeout: 1)

        XCTAssertNotNil(expenseData)
        XCTAssertEqual(expenseData!.name, "Expense 2")
        XCTAssertEqual(expenseData!.payerName, "User 3")
        XCTAssertEqual(expenseData!.amount, 90.0)
        XCTAssertEqual(expenseData!.expenseTypeIndex, 1)

        XCTAssertEqual(expenseData!.weights[0].name, DisplayModelMocks.participant1.name)
        XCTAssertEqual(expenseData!.weights[0].weight, 1/3)
        XCTAssertEqual(expenseData!.weights[1].name, DisplayModelMocks.participant2.name)
        XCTAssertEqual(expenseData!.weights[1].weight, 1/3)
        XCTAssertEqual(expenseData!.weights[2].name, DisplayModelMocks.participant3.name)
        XCTAssertEqual(expenseData!.weights[2].weight, 1/3)
        XCTAssertFalse(expenseData!.weights.contains { $0.name == DisplayModelMocks.participant4.name })
    }

    func testCreateExpenseSplitAmountDefault() {
        RunLoop.main.run(mode: .default, before: .distantPast)
        viewModel.send(event: .onNameChange("Expense 3"))
        viewModel.send(event: .onAmountChange("50"))
        viewModel.send(event: .onSplitEquallyChange(false))
        viewModel.send(event: .onExpenseTypeChange(1))

        let expectation = XCTestExpectation(description: "expense created")

        var expenseData: DataRequesting.ExpenseData?
        mock.onCreate = { result in
            expenseData = result
            expectation.fulfill()
        }

        viewModel.send(event: .onSaveExpense)
        wait(for: [expectation], timeout: 1)

        XCTAssertNotNil(expenseData)
        XCTAssertEqual(expenseData!.name, "Expense 3")
        XCTAssertEqual(expenseData!.payerName, "User 1")
        XCTAssertEqual(expenseData!.amount, 50.0)
        XCTAssertEqual(expenseData!.expenseTypeIndex, 2)

        XCTAssertEqual(expenseData!.weights[0].name, DisplayModelMocks.participant1.name)
        XCTAssertEqual(expenseData!.weights[0].weight, 0.25)
        XCTAssertEqual(expenseData!.weights[1].name, DisplayModelMocks.participant2.name)
        XCTAssertEqual(expenseData!.weights[1].weight, 0.25)
        XCTAssertEqual(expenseData!.weights[2].name, DisplayModelMocks.participant3.name)
        XCTAssertEqual(expenseData!.weights[2].weight, 0.25)
        XCTAssertEqual(expenseData!.weights[3].name, DisplayModelMocks.participant4.name)
        XCTAssertEqual(expenseData!.weights[3].weight, 0.25)
    }

    func testCreateExpenseSplitAmountCustom() {
        RunLoop.main.run(mode: .default, before: .distantPast)
        viewModel.send(event: .onNameChange("Expense 3"))
        viewModel.send(event: .onAmountChange("50"))
        viewModel.send(event: .onSplitEquallyChange(false))
        viewModel.send(event: .onExpenseTypeChange(1))
        viewModel.send(event: .onExpenseTypeAmountChange(0, amount: "10"))
        viewModel.send(event: .onExpenseTypeAmountChange(1, amount: "5"))
        viewModel.send(event: .onExpenseTypeAmountChange(2, amount: "15"))
        viewModel.send(event: .onExpenseTypeAmountChange(3, amount: "20"))

        let expectation = XCTestExpectation(description: "expense created")

        var expenseData: DataRequesting.ExpenseData?
        mock.onCreate = { result in
            expenseData = result
            expectation.fulfill()
        }

        viewModel.send(event: .onSaveExpense)
        wait(for: [expectation], timeout: 1)

        XCTAssertNotNil(expenseData)
        XCTAssertEqual(expenseData!.name, "Expense 3")
        XCTAssertEqual(expenseData!.payerName, "User 1")
        XCTAssertEqual(expenseData!.amount, 50.0)
        XCTAssertEqual(expenseData!.expenseTypeIndex, 2)

        XCTAssertEqual(expenseData!.weights[0].name, DisplayModelMocks.participant1.name)
        XCTAssertEqual(expenseData!.weights[0].weight, 0.2)
        XCTAssertEqual(expenseData!.weights[1].name, DisplayModelMocks.participant2.name)
        XCTAssertEqual(expenseData!.weights[1].weight, 0.1)
        XCTAssertEqual(expenseData!.weights[2].name, DisplayModelMocks.participant3.name)
        XCTAssertEqual(expenseData!.weights[2].weight, 0.3)
        XCTAssertEqual(expenseData!.weights[3].name, DisplayModelMocks.participant4.name)
        XCTAssertEqual(expenseData!.weights[3].weight, 0.4)
    }
}

extension NewExpenseViewModel.State: Equatable {
    public static func == (lhs: NewExpenseViewModel.State, rhs: NewExpenseViewModel.State) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.loaded, .loaded):
            return true
        default:
            return false
        }
    }
}
