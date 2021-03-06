//
//  DataRequesting.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 18/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import Combine

protocol DataRequesting {

    // MARK: - Split
    typealias SplitId = Int64

    func splits() -> AnyPublisher<[SplitDTO], Never>
    func split(withId id: SplitId) -> AnyPublisher<SplitDTO?, Never>
    func createSplit(name: String, participants: [String]) -> AnyPublisher<Void, Never>
    func updateSplit(id: SplitId, name: String, newParticipants: [String]) -> AnyPublisher<Void, Never>
    func removeSplit(id: SplitId) -> AnyPublisher<Void, Never>

    // MARK: - Expense

    typealias ExpenseId = Int64
    typealias ExpenseTypeIndex = Int
    typealias ExpenseData = (name: String, payerName: String, amount: Double, weights: [ParticipantExpenseWeight], expenseTypeIndex: ExpenseTypeIndex)
    typealias ParticipantExpenseWeight = (name: String, weight: Double)

    func expense(expenseId: ExpenseId) -> AnyPublisher<ExpenseDTO?, Never>
    func createExpense(splitId: SplitId, expenseData: ExpenseData) -> AnyPublisher<Void, Never>
    func updateExpense(withId id: ExpenseId, expenseData: ExpenseData) -> AnyPublisher<Void, Never>
    func removeExpense(withId id: ExpenseId) -> AnyPublisher<Void, Never>
}
