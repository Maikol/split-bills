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
