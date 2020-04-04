//
//  SplitViewModel.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 4/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

final class SplitViewModel {

    let split: Split
    var expenses = [Expense]()

    private unowned let coordinator: MainCoordinator

    var payments: [Payment] {
        split.settle(expenses: expenses)
    }

    init(split: Split, coordinator: MainCoordinator) {
        self.split = split
        self.coordinator = coordinator
    }

    // MARK: Split

    func editSplit() {
        coordinator.editSplit(split: split)
    }

    func deleteSplit() {
        SplitController.shared.remove(split: split)
        coordinator.splitDeleted()
    }

    // MARK: Expenses

    func newExpense() {
        coordinator.open(split: split, expense: nil)
    }

    func open(expense: Expense) {
        coordinator.open(split: split, expense: expense)
    }

    func delete(expense: Expense) -> Bool {
        guard ExpenseController.shared.remove(expense: expense) else {
            return false
        }

        reloadExpenses()
        return true
    }

    func reloadExpenses() {
        expenses = ExpenseController.shared.getAll(for: split)
    }
}
