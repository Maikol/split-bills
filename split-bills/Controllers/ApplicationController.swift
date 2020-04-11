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

    func update(split: Split) {
        do {
            try splitDatabase.update(split: split)
        } catch {
            print("failed to update split")
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
