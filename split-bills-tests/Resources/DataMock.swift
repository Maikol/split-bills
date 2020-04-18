//
//  DataMock.swift
//  split-bills-tests
//
//  Created by Carlos Miguel de Elias on 18/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import Combine
@testable import split_bills

class DataMock: DataRequesting {

    func splits() -> AnyPublisher<[SplitDTO], Never> {
        Empty().eraseToAnyPublisher()
    }

    func split(withId id: SplitId) -> AnyPublisher<SplitDTO?, Never> {
        return Deferred {
            Future<SplitDTO?, Never> { promise in
                promise(.success(DTOMocks.splits[Int(truncatingIfNeeded: id)]))
            }
        }.eraseToAnyPublisher()
    }

    func createSplit(name: String, participants: [String]) -> AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    func updateSplit(id: SplitId, name: String, newParticipants: [String]) -> AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    func removeSplit(id: SplitId) -> AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    func expense(expenseId: ExpenseId) -> AnyPublisher<ExpenseDTO?, Never> {
        Empty().eraseToAnyPublisher()
    }

    func createExpense(splitId: SplitId, expenseData: ExpenseData) -> AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    func updateExpense(withId id: ExpenseId, expenseData: ExpenseData) -> AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    func removeExpense(withId id: ExpenseId) -> AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }
}
