//
//  SplitListViewModelTests.swift
//  split-bills-tests
//
//  Created by Carlos DeElias on 24/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import XCTest
@testable import split_bills
import Combine


class SplitListViewModelTests: XCTestCase {

    final class DataMock: EmptyDataMock {

        var storedSplits = DTOMocks.splits

        override func splits() -> AnyPublisher<[SplitDTO], Never> {
            return Deferred {
                Future<[SplitDTO], Never> { promise in
                    promise(.success(self.storedSplits))
                }
            }.eraseToAnyPublisher()
        }

        override func removeSplit(id: EmptyDataMock.SplitId) -> AnyPublisher<Void, Never> {
            return Deferred {
                Future<Void, Never> { promise in
                    self.storedSplits.removeAll { $0.id == id }
                    promise(.success(()))
                }
            }.eraseToAnyPublisher()
        }
    }

    var mock: DataMock!
    var viewModel: SplitListViewModel?

    private var bag = Set<AnyCancellable>()

    override func setUpWithError() throws {
        mock = DataMock()
        viewModel = SplitListViewModel(datasource: mock)
    }

    func testViewModelStateLoaded() {
        XCTAssertEqual(viewModel!.state, .idle)

        let loadingExpectation = XCTestExpectation(description: "split list loading")
        viewModel!.$state.sink { state in
            guard case .loading = state else { return }
            loadingExpectation.fulfill()
        }.store(in: &bag)

        viewModel!.send(event: .onAppear)
        wait(for: [loadingExpectation], timeout: 1)

        let loadedExpectation = XCTestExpectation(description: "split list loaded")
        viewModel!.$state.sink { state in
            guard case .loaded = state else { return }
            loadedExpectation.fulfill()
        }.store(in: &bag)

        wait(for: [loadedExpectation], timeout: 1)
        XCTAssertEqual(mock.storedSplits.count, 2)
        XCTAssertEqual(viewModel!.state, .loaded(mock.storedSplits.map { .init(split: $0) }))

        let removedExpectation = XCTestExpectation(description: "split deleted")
        viewModel!.send(event: .onRemoveSplit(.init(split: mock.storedSplits.first!)))

        viewModel!.$state.sink { state in
            guard case let .loaded(splits) = state, splits.count == 1 else { return }
            removedExpectation.fulfill()
        }.store(in: &bag)

        wait(for: [removedExpectation], timeout: 1)
        XCTAssertEqual(mock.storedSplits.count, 1)
        XCTAssertEqual(viewModel!.state, .loaded(mock.storedSplits.map { .init(split: $0) }))
    }

    func testNewActiveSheet() {
        let loadedExpectation = XCTestExpectation(description: "split list loaded")
        viewModel!.$state.sink { state in
            guard case .loaded = state else { return }
            loadedExpectation.fulfill()
        }.store(in: &bag)

        viewModel!.send(event: .onAppear)
        wait(for: [loadedExpectation], timeout: 1)

        viewModel!.presentSheet(with: .new)

        XCTAssertNotNil(viewModel!.activeSheet)
        XCTAssertEqual(viewModel!.activeSheet, .init(style: .new))
    }

    func testEditActiveSheet() {
        let loadedExpectation = XCTestExpectation(description: "split list loaded")
        viewModel!.$state.sink { state in
            guard case .loaded = state else { return }
            loadedExpectation.fulfill()
        }.store(in: &bag)

        viewModel!.send(event: .onAppear)
        wait(for: [loadedExpectation], timeout: 1)

        viewModel!.presentSheet(with: .edit(.init(split: DTOMocks.splits.first!)))

        XCTAssertNotNil(viewModel!.activeSheet)
        XCTAssertEqual(viewModel!.activeSheet, .init(style: .edit(.init(split: DTOMocks.splits.first!))))
    }
}

extension SplitListViewModel.State: Equatable {

    public static func == (lhs: SplitListViewModel.State, rhs: SplitListViewModel.State) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case let (.loaded(leftItems), .loaded(rightItems)):
            return leftItems == rightItems
        default:
            return false
        }
    }
}

extension SplitListViewModel.Sheet: Equatable {

    public static func == (lhs: SplitListViewModel.Sheet, rhs: SplitListViewModel.Sheet) -> Bool {
        switch (lhs.style, rhs.style) {
        case (.new, .new):
            return true
        case let (.edit(leftSplit), .edit(rightSplit)):
            return leftSplit.id == rightSplit.id
        default:
            return false
        }
    }
}
