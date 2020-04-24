//
//  SplitDetailViewModelPerformanceTests.swift
//  split-bills-tests
//
//  Created by Carlos DeElias on 22/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import XCTest
@testable import split_bills
import Combine

final class SplitDetailViewModelPerformanceTests: XCTestCase {

    var mock: EmptyDataMock!
    var viewModel: SplitDetailViewModel!

    private var bag = Set<AnyCancellable>()

    override func setUpWithError() throws {
        super.setUp()

        mock = EmptyDataMock()
        viewModel = SplitDetailViewModel(splitId: 1, title: "Split Title", datasource: mock)
        viewModel.send(event: .onAppear)
    }

    func testPaymentstPerforamnce() {
        let expectation = XCTestExpectation(description: "split details loaded")

        var item: SplitDetailViewModel.ListItem?

        viewModel.$state.sink { state in
            guard case let .loaded(loadedItem) = state else { return }
            item = loadedItem
            expectation.fulfill()
        }.store(in: &bag)

        wait(for: [expectation], timeout: 1)
        XCTAssertNotNil(item)

        measure {
            let _ = item!.payments
        }
    }
}
