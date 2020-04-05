//
//  SplitController.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

final class SplitController: ObservableObject {

    @Published var splits: [Split]

    static let shared = SplitController()

    private let splitDatabase: SplitDatabase

    init() {
        splitDatabase = try! SplitDatabase(databasePath: URL.documentsDirectory.path)
        splits = try! splitDatabase.getAll()
    }

    func create(eventName: String, participants: [Participant]) -> Split? {
        do {
            return try self.splitDatabase.create(eventName: eventName, participants: participants)
        } catch {
            print("failed to add split item")
            return nil
        }
    }

    func remove(split: Split) {
        do {
            try self.splitDatabase.remove(split: split)
        } catch {
            print("failed to delete split item")
        }
    }
}

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
        try? expensesDatabase?.add(expense: expense, splitName: split.eventName)
    }

    func update(expense: Expense) {
        try? expensesDatabase?.update(expense: expense)
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
