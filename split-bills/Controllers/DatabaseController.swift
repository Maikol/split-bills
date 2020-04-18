//
//  DatabaseController.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import Combine

enum DatabaseAPI {

    typealias SplitId = Int64
    typealias ExpenseId = Int64
    typealias ExpenseTypeIndex = Int

    typealias ParticipantExpenseWeight = (name: String, weight: Double)

    static func splits() -> AnyPublisher<[SplitDTO], Never> {
        return Deferred {
            Future<[SplitDTO], Never> { promise in
                let splitDatabase = try! SplitDatabase(databasePath: URL.documentsDirectory.path)
                let splits = try! splitDatabase.latestSplits()
                promise(.success(splits))
            }
        }.eraseToAnyPublisher()
    }

    static func split(withId id: SplitId) -> AnyPublisher<SplitDTO?, Never> {
        return Deferred {
            Future<SplitDTO?, Never> { promise in
                let splitDatabase = try! SplitDatabase(databasePath: URL.documentsDirectory.path)
                let split = try! splitDatabase.split(withId: id)
                promise(.success(split))
            }
        }.eraseToAnyPublisher()
    }

    static func createSplit(name: String, participants: [String]) -> AnyPublisher<Void, Never> {
        return Deferred {
            Future<Void, Never> { promise in
                let splitDatabase = try! SplitDatabase(databasePath: URL.documentsDirectory.path)
                try! splitDatabase.create(eventName: name, participants: participants)
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    static func updateSplit(id: SplitId, name: String, newParticipants: [String]) -> AnyPublisher<Void, Never> {
        return Deferred {
            Future<Void, Never> { promise in
                let splitDatabase = try! SplitDatabase(databasePath: URL.documentsDirectory.path)
                _ = try! splitDatabase.update(splitId: id, name: name, newParticipants: newParticipants)
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    static func removeSplit(id: SplitId, name: String) -> AnyPublisher<Void, Never> {
        return Deferred {
            Future<Void, Never> { promise in
                let splitDatabase = try! SplitDatabase(databasePath: URL.documentsDirectory.path)
                try! splitDatabase.remove(splitId: id)
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    static func expense(expenseId: ExpenseId) -> AnyPublisher<ExpenseDTO?, Never> {
        return Deferred {
            Future<ExpenseDTO?, Never> { promise in
                let expensesDatabase = try! ExpenseDatabase(databasePath: URL.documentsDirectory.path)
                let expense = try! expensesDatabase.expense(withId: expenseId)
                promise(.success(expense))
            }
        }.eraseToAnyPublisher()
    }

    static func createExpense(
        splitId: SplitId,
        name: String,
        payerName: String,
        amount: Double,
        weights: [ParticipantExpenseWeight],
        expenseTypeIndex: ExpenseTypeIndex
    ) -> AnyPublisher<Void, Never> {
        return Deferred {
            Future<Void, Never> { promise in
                let expensesDatabase = try! ExpenseDatabase(databasePath: URL.documentsDirectory.path)
                let weightsDTO = weights.map { ExpenseWeightDTO(participant: .init(name: $0.name), weight: $0.weight) }
                try! expensesDatabase.create(splitId: splitId, name: name, payerName: payerName, amount: amount, weights: weightsDTO, expenseTypeIndex: expenseTypeIndex)
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    static func updateExpense(
        withId id: ExpenseId,
        name: String,
        payerName: String,
        amount: Double,
        weights: [ParticipantExpenseWeight],
        expenseTypeIndex: ExpenseTypeIndex
    ) -> AnyPublisher<Void, Never> {
        return Deferred {
            Future<Void, Never> { promise in
                let expensesDatabse = try! ExpenseDatabase(databasePath: URL.documentsDirectory.path)
                let weightsDTO = weights.map { ExpenseWeightDTO(participant: .init(name: $0.name), weight: $0.weight) }
                try! expensesDatabse.update(expenseId: id, name: name, payerName: payerName, amount: amount, weights: weightsDTO, expenseTypeIndex: expenseTypeIndex)
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }
}

// MARK: - DTOs

struct SplitDTO {
    let id: Int64
    let name: String
    let participants: [ParticipantDTO]
    let expenses: [ExpenseDTO]

    static let empty = SplitDTO(id: 0, name: "", participants: [], expenses: [])
}

struct ParticipantDTO: Equatable {
    let name: String
}

struct ExpenseDTO {
    let id: Int64
    let name: String
    let payer: ParticipantDTO
    let amount: Double
    let participantsWeight: [ExpenseWeightDTO]
    let expenseType: ExpenseTypeDTO

    static let empty = ExpenseDTO(id: 0, name: "", payer: .init(name: ""), amount: 0, participantsWeight: [], expenseType: .equallyWithAll)
}

struct ExpenseWeightDTO {
    let participant: ParticipantDTO
    let weight: Double
}

enum ExpenseTypeDTO: Int {
    case equallyWithAll
    case equallyCustom
    case byAmount
}

extension URL {

    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsURL = paths.first else {
            print("Missing a documents directory")
            fatalError()
        }

        return documentsURL
    }
}

#if DEBUG
extension SplitDTO {
    static let example = SplitDTO(id: 0, name: "Dinner", participants: .example, expenses: [])
}

extension ExpenseDTO {
    static let example = ExpenseDTO(id: 0, name: "Wine", payer: .bob, amount: 20, participantsWeight: .example, expenseType: .equallyWithAll)
}

extension ParticipantDTO {
    static let bob = ParticipantDTO(name: "Bob")
    static let alice = ParticipantDTO(name: "Alice")
}

extension Array where Element == ParticipantDTO {
    static let example: [ParticipantDTO] = [.bob, .alice]
}

extension Array where Element == ExpenseDTO {
    static let example: [ExpenseDTO] = [.init(
        id: 0,
        name: "drinks",
        payer: .alice,
        amount: 40.0,
        participantsWeight: [.init(participant: .alice, weight: 0.5), .init(participant: .bob, weight: 0.5)],
        expenseType: .equallyWithAll)
    ]
}

extension Array where Element == ExpenseWeightDTO {
    static let example: [ExpenseWeightDTO] = [
        .init(participant: .bob, weight: 0.5),
        .init(participant: .alice, weight: 0.5)
    ]
}
#endif
