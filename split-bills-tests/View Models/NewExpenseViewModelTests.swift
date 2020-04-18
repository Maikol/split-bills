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

    var viewModel: NewExpenseViewModel!

    private var bag = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()

        viewModel = NewExpenseViewModel(splitId: 0)
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
