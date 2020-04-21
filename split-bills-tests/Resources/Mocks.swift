//
//  Mocks.swift
//  split-bills-tests
//
//  Created by Carlos Miguel de Elias on 23/2/19.
//  Copyright © 2019 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
@testable import split_bills

enum DTOMocks {
    static let splits = [
        SplitDTO(id: 0, name: "Test 1", participants: participants, expenses: [expense1, expense2]),
        splitWithMultipleRandomExpenses
    ]

    static let splitWithMultipleRandomExpenses: SplitDTO = {
        var expenses = [ExpenseDTO]()

        for i in 0...100000 {
            let amount = Double.random(in: 1..<100)
            let expense = ExpenseDTO(id: Int64(i), name: "Expense \(i)", payer: participants.randomElement()!, amount: amount, participantsWeight: participants.map { ExpenseWeightDTO(participant: $0, weight: 0.25) }, expenseType: .equallyWithAll)
            expenses.append(expense)
        }

        return SplitDTO(id: 1, name: "Test 1", participants: participants, expenses: expenses)
    }()
    
    static let participant1 = ParticipantDTO(name: "User 1")
    static let participant2 = ParticipantDTO(name: "User 2")
    static let participant3 = ParticipantDTO(name: "User 3")
    static let participant4 = ParticipantDTO(name: "User 4")

    static let participants = [participant1, participant2, participant3, participant4]

    static let expense1 = ExpenseDTO(id: 1, name: "Expense 1 test", payer: participant1, amount: 100.0, participantsWeight: participants.map { ExpenseWeightDTO(participant: $0, weight: 0.25) }, expenseType: .equallyWithAll)
    static let expense2 = ExpenseDTO(id: 2, name: "Expense 2 test", payer: participant2, amount: 50.0, participantsWeight: participants.map { ExpenseWeightDTO(participant: $0, weight: 0.25) }, expenseType: .equallyWithAll)
}

enum DisplayModelMocks {
    static let participant1 = ParticipantDisplayModel(name: "User 1")
    static let participant2 = ParticipantDisplayModel(name: "User 2")
    static let participant3 = ParticipantDisplayModel(name: "User 3")
    static let participant4 = ParticipantDisplayModel(name: "User 4")

    static let participants = [participant1, participant2, participant3, participant4]

    static let expense1 = ExpenseDisplayModel(expense: DTOMocks.expense1)
    static let expense2 = ExpenseDisplayModel(expense: DTOMocks.expense2)

    static let expenses = [expense1, expense2]
}
