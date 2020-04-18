//
//  DatabaseAPI.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import Combine

struct DatabaseAPI: DataRequesting {

    static let shared = DatabaseAPI()

    private let splitDatabase = try! SplitDatabase(databasePath: URL.documentsDirectory.path)
    private let expensesDatabase = try! ExpenseDatabase(databasePath: URL.documentsDirectory.path)

    func splits() -> AnyPublisher<[SplitDTO], Never> {
        return Deferred {
            Future<[SplitDTO], Never> { promise in
                let splits = try! self.splitDatabase.getAll()
                promise(.success(splits))
            }
        }.eraseToAnyPublisher()
    }

    func split(withId id: SplitId) -> AnyPublisher<SplitDTO?, Never> {
        return Deferred {
            Future<SplitDTO?, Never> { promise in
                let split = try! self.splitDatabase.split(withId: id)
                promise(.success(split))
            }
        }.eraseToAnyPublisher()
    }

    func createSplit(name: String, participants: [String]) -> AnyPublisher<Void, Never> {
        return Deferred {
            Future<Void, Never> { promise in
                try! self.splitDatabase.create(eventName: name, participants: participants)
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    func updateSplit(id: SplitId, name: String, newParticipants: [String]) -> AnyPublisher<Void, Never> {
        return Deferred {
            Future<Void, Never> { promise in
                _ = try! self.splitDatabase.update(splitId: id, name: name, newParticipants: newParticipants)
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    func removeSplit(id: SplitId) -> AnyPublisher<Void, Never> {
        return Deferred {
            Future<Void, Never> { promise in
                try! self.splitDatabase.remove(splitId: id)
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    func expense(expenseId: ExpenseId) -> AnyPublisher<ExpenseDTO?, Never> {
        return Deferred {
            Future<ExpenseDTO?, Never> { promise in
                let expense = try! self.expensesDatabase.expense(withId: expenseId)
                promise(.success(expense))
            }
        }.eraseToAnyPublisher()
    }

    func createExpense(splitId: SplitId, expenseData: ExpenseData) -> AnyPublisher<Void, Never> {
        return Deferred {
            Future<Void, Never> { promise in
                let weightsDTO = expenseData.weights.map { ExpenseWeightDTO(participant: .init(name: $0.name), weight: $0.weight) }
                try! self.expensesDatabase.create(
                    splitId: splitId,
                    name: expenseData.name,
                    payerName: expenseData.payerName,
                    amount: expenseData.amount,
                    weights: weightsDTO,
                    expenseTypeIndex: expenseData.expenseTypeIndex)
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    func updateExpense(withId id: ExpenseId, expenseData: ExpenseData) -> AnyPublisher<Void, Never> {
        return Deferred {
            Future<Void, Never> { promise in
                let weightsDTO = expenseData.weights.map { ExpenseWeightDTO(participant: .init(name: $0.name), weight: $0.weight) }
                try! self.expensesDatabase.update(
                    expenseId: id,
                    name: expenseData.name,
                    payerName: expenseData.payerName,
                    amount: expenseData.amount,
                    weights: weightsDTO,
                    expenseTypeIndex: expenseData.expenseTypeIndex)
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    func removeExpense(withId id: ExpenseId) -> AnyPublisher<Void, Never> {
        return Deferred {
            Future<Void, Never> { promise in
                try! self.expensesDatabase.remove(expenseId: id)
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }
}

extension URL {

    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsURL = paths.first else {
            fatalError("Missing a documents directory")
        }

        return documentsURL
    }
}
