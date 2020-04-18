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

enum DataMock: DataRequesting {

    static func splits() -> AnyPublisher<[SplitDTO], Never> {
        Empty().eraseToAnyPublisher()
    }

    static func split(withId id: SplitId) -> AnyPublisher<SplitDTO?, Never> {
        return Deferred {
            Future<SplitDTO?, Never> { promise in
                promise(.success(DTOMocks.splits[Int(truncatingIfNeeded: id)]))
            }
        }.eraseToAnyPublisher()
    }

    static func createSplit(name: String, participants: [String]) -> AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    static func updateSplit(id: SplitId, name: String, newParticipants: [String]) -> AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    static func removeSplit(id: SplitId) -> AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    static func expense(expenseId: ExpenseId) -> AnyPublisher<ExpenseDTO?, Never> {
        Empty().eraseToAnyPublisher()
    }

    static func createExpense(splitId: SplitId, expenseData: ExpenseData) -> AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    static func updateExpense(withId id: ExpenseId, expenseData: ExpenseData) -> AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    static func removeExpense(withId id: ExpenseId) -> AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }
}
