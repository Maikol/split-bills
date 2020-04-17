//
//  ExpenseEditModel.swift
//  split-bills
//
//  Created by Carlos DeElias on 17/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

struct ExpenseEditModel: Builder {

    var payerIndex = 0
    var name = ""
    var amount = ""
    var splitEqually = true
    var expenseTypeIndex = 0
    let participants: [ParticipantDisplayModel]
    var expenseTypeSelections: [ExpenseTypeEditModel.Selection]
    var expenseTypeAmounts: [ExpenseTypeEditModel.Amount]

    init(participants: [ParticipantDisplayModel]) {
        self.participants = participants
        expenseTypeSelections = participants.map { .init(participant: $0) }
        expenseTypeAmounts = participants.map { .init(participant: $0) }
    }

    private var selectedExpenseType: ExpenseTypeEditModel {
        ExpenseTypeEditModel(index: expenseTypeIndex)
    }

    var isValid: Bool {
        guard !name.isEmpty,
            let amount = Double(amount), amount > 0 else
        {
            return false
        }

        if splitEqually {
            return true
        }

        switch selectedExpenseType {
        case .equally:
            return expenseTypeSelections.contains { $0.isSelected }
        case .amount:
            let doubleAmounts = expenseTypeAmounts.compactMap { Double($0.amount) }
            let participantsAmount = doubleAmounts.reduce(0, +)
            return fabs(1 - (amount/participantsAmount)) < 0.01
        }
    }

    var payerName: String {
        participants[payerIndex].name
    }

    typealias Weight = (name: String, weight: Double)

    var weights: [Weight] {


        if splitEqually {
            return splitEqually(with: participants)
        }

        switch selectedExpenseType {
        case .equally:
            let participants = expenseTypeSelections
                .filter { $0.isSelected }
                .map { $0.participant }
            return splitEqually(with: participants)
        case .amount:
            return splitByAmount
        }
    }

    private func splitEqually(with participants: [ParticipantDisplayModel]) -> [Weight] {
        precondition(participants.count > 0, "We can calculate with no participants")
        let weight = 1 / Double(participants.count)
        return participants.map { (name: $0.name, weight: weight) }
    }

    private var splitByAmount: [Weight] {
        guard let amount = Double(amount) else {
            fatalError("Can't save an expense with a non double value")
        }

        precondition(amount > 0, "Expense needs to have a valid amoun")
        precondition(expenseTypeAmounts.count > 0, "There needs to be at least one participant")

        return expenseTypeAmounts.map { (name: $0.participant.name, weight: (Double($0.amount) ?? 0 / amount)) }
    }
}
