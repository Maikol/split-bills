//
//  SplitController.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

final class ApplicationController: ObservableObject {

    @Published var splits: [Split]

    // Legacy
    static let shared = ApplicationController()

    private let splitDatabase: SplitDatabase
    private let expensesDatabase: ExpenseDatabase

    init() {
        splitDatabase = try! SplitDatabase(databasePath: URL.documentsDirectory.path)
        expensesDatabase = try! ExpenseDatabase(databasePath: URL.documentsDirectory.absoluteString)
        splits = try! splitDatabase.getAll()
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

    @discardableResult func saveExpense(split: Split, expense: Expense) -> Expense? {
        do {
            let result = try expensesDatabase.add(expense: expense, splitName: split.eventName)
            split.expenses.append(result)
            return result
        } catch {
            print("failed to create expense")
            return nil
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
}

// Legacy
struct ExpenseController {

    static let shared = ExpenseController()

    private let expensesDatabase: ExpenseDatabase?

    init() {
        do {
            expensesDatabase = try ExpenseDatabase(databasePath: URL.documentsDirectory.absoluteString)
        } catch {
            expensesDatabase = nil
        }
    }

    func add(expense: Expense, in split: Split) {
        _ = ((try? expensesDatabase?.add(expense: expense, splitName: split.eventName)) as Expense??)
    }

    func update(expense: Expense) {
        ((try? expensesDatabase?.update(expense: expense)) as ()??)
    }

    func remove(expense: Expense) -> Bool {
        guard let expenseDatabase = self.expensesDatabase else {
            return false
        }

        do {
            try expenseDatabase.remove(expense: expense)
            return true
        } catch {
            return false
        }
    }

    func getAll(for split: Split) -> [Expense] {
        guard let expensesDatabase = expensesDatabase else {
            return []
        }

        do {
            return try expensesDatabase.getAll(splitName: split.eventName)
        } catch {
            return []
        }
    }
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
