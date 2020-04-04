//
//  NewExpenseViewModel.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 4/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

final class NewExpenseViewModel {

    let split: Split
    let expense: Expense?

    private let coordinator: MainCoordinator

    init(split: Split, expense: Expense?, coordinator: MainCoordinator) {
        self.split = split
        self.expense = expense
        self.coordinator = coordinator
    }

    func save(expense: Expense) {
        store(expense: expense)
        coordinator.dismissExpense()
    }

    func saveAndCreate(expense: Expense) {
        store(expense: expense)
        coordinator.open(split: split, expense: nil)
    }

    private func store(expense: Expense) {
        if expense.id != INT64_MAX {
            ExpenseController.shared.update(expense: expense)
        } else {
            ExpenseController.shared.add(expense: expense, in: split)
        }
    }
}
