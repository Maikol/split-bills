//
//  SplitController.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

struct SplitController {

    static let shared = SplitController()

    private let splitDatabase: SplitDatabase?

    init() {
        do {
            splitDatabase = try SplitDatabase(databasePath: URL.documentsDirectory.absoluteString)
        } catch {
            splitDatabase = nil
        }
    }

    func add(split: Split) {
        do {
            try self.splitDatabase?.add(split: split)
        } catch {
            print("failed to add split item")
        }
    }

    func remove(split: Split) {
        do {
            try self.splitDatabase?.remove(split: split)
        } catch {
            print("failed to delete split item")
        }
    }

    func getAll() -> [Split]? {
        do {
            return try self.splitDatabase?.getAll()
        } catch {
            print("failed to get split items")
            return nil
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
