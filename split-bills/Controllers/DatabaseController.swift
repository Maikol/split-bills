//
//  DatabaseController.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import Combine

final class DatabaseController: ObservableObject {

    @Published var splits: [Split]

    // Legacy
    static let shared = DatabaseController()

    private let splitDatabase: SplitDatabase
    private let expensesDatabase: ExpenseDatabase

    init() {
        splitDatabase = try! SplitDatabase(databasePath: URL.documentsDirectory.path)
        expensesDatabase = try! ExpenseDatabase(databasePath: URL.documentsDirectory.absoluteString)
        splits = []
    }

    @discardableResult func createEvent(name: String, participants: [Participant]) -> Split? {
        do {
            let split = try self.splitDatabase.create(eventName: name, participants: participants)
            self.splits.append(split)
            return split
        } catch {
            print("failed to add split item")
            return nil
        }
    }

    func update(split: Split) {
        do {
            try splitDatabase.update(split: split)
        } catch {
            print("failed to update split")
        }
    }

    @discardableResult func saveExpense(split: Split, expense: Expense) -> Expense? {
        do {
            return nil
        } catch {
            print("failed to create expense")
            return nil
        }
    }

    func update(expense: Expense, on split: Split) {
        guard let index = split.expenses.firstIndex(where: { $0.id == expense.id }) else {
            print("failed to update expense")
            return
        }

        do {
            try expensesDatabase.update(expense: expense)
            split.expenses[index] = expense
        } catch {
            print("failed to update expense")
        }
    }

    func remove(split: Split) {
        do {
            try self.splitDatabase.remove(split: split)
            splits.removeAll { $0.id == split.id }
        } catch {
            print("failed to delete split item")
        }
    }

    func remove(expense: Expense, on split: Split) {
        do {
            try expensesDatabase.remove(expense: expense)
            split.expenses.removeAll { $0.id == expense.id }
        } catch {
            print("failed to remove expense")
        }
    }
}

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
                let splits = try! splitDatabase.split(withId: id)
                promise(.success(splits))
            }
        }.eraseToAnyPublisher()
    }

    static func createSplit(name: String, participants: [String]) -> AnyPublisher<Void, Never> {
        return Deferred {
            Future<Void, Never> { promise in
                let splitDatabase = try! SplitDatabase(databasePath: URL.documentsDirectory.path)
                _ = try! splitDatabase.create(eventName: name, participants: participants.map { .init(name: $0) })
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    static func updateSplit(id: SplitId, name: String, newParticipants: [String]) -> AnyPublisher<Void, Never> {
        return Deferred {
            Future<Void, Never> { promise in
                let splitDatabase = try! SplitDatabase(databasePath: URL.documentsDirectory.path)
                _ = try! splitDatabase.update(splitId: id, name: name, newParticipants: newParticipants.map { .init(name: $0) })
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    static func removeSplit(id: SplitId, name: String) -> AnyPublisher<Void, Never> {
        return Deferred {
            Future<Void, Never> { promise in
                let splitDatabase = try! SplitDatabase(databasePath: URL.documentsDirectory.path)
                try! splitDatabase.remove(split: Split(id: id, eventName: name, participants: []))
                promise(.success(()))
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

struct ParticipantDTO {
    let name: String
}

struct ExpenseDTO {
    let id: Int64
    let name: String
    let payer: ParticipantDTO
    let amount: Double
    let participantsWeight: [ExpenseWeightDTO]
    let expenseType: ExpenseTypeDTO
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
#endif
