//
//  SplitDetailViewModelTests.swift
//  split-bills-tests
//
//  Created by Carlos Miguel de Elias on 11/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import XCTest
@testable import split_bills
import Combine

final class SplitDetailViewModelTests: XCTestCase {

    var mock: DataMock!
    var viewModel: SplitDetailViewModel!

    private var bag = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()

        mock = DataMock()
        viewModel = SplitDetailViewModel(splitId: 0, title: "Split Title", datasource: mock)
        viewModel.send(event: .onAppear)
    }

    func testViewModelStateLoaded() {
        let expectation = XCTestExpectation(description: "split details loaded")

        viewModel.$state.sink { state in
            guard case .loaded = state else { return }
            expectation.fulfill()
        }.store(in: &bag)

        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(viewModel.state == .loaded(.init(split: .init(split: DTOMocks.splits[0]), expenses: DisplayModelMocks.expenses)))
    }

    func testPayment() {
        let expectation = XCTestExpectation(description: "split details loaded")

        var item: SplitDetailViewModel.ListItem?

        viewModel.$state.sink { state in
            guard case let .loaded(loadedItem) = state else { return }
            item = loadedItem
            expectation.fulfill()
        }.store(in: &bag)

        wait(for: [expectation], timeout: 1)
        XCTAssertNotNil(item)

        let payments = item!.payments
        XCTAssertEqual(payments.count, 3)
        XCTAssertEqual(payments[0].amount, 37.5)
        XCTAssertEqual(payments[1].amount, 25)
        XCTAssertEqual(payments[2].amount, 12.5)

        let payers = payments.map { $0.payer }
        XCTAssertTrue(payers.contains(DisplayModelMocks.participant3))
        XCTAssertTrue(payers.contains(DisplayModelMocks.participant4))
        XCTAssertFalse(payers.contains(DisplayModelMocks.participant1))

        let receivers = payments.map { $0.receiver }
        XCTAssertTrue(receivers.contains(DisplayModelMocks.participant1))
        XCTAssertTrue(receivers.contains(DisplayModelMocks.participant2))
        XCTAssertFalse(receivers.contains(DisplayModelMocks.participant3))
        XCTAssertFalse(receivers.contains(DisplayModelMocks.participant4))
    }
}

extension SplitDetailViewModel.State: Equatable {
    public static func == (lhs: SplitDetailViewModel.State, rhs: SplitDetailViewModel.State) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.loaded, .loaded):
            return true
        case (.reloading, .reloading):
            return true
        default:
            return false
        }
    }
}
