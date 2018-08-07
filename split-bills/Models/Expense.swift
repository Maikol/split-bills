//
//  Expense.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 7/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

struct Expense {

    let id: Int64
    let payer: Participant
    let description: String
    let amount: Double
    let participantsWeight: [ExpenseWeight]
}

struct ExpenseWeight {

    let participant: Participant
    let weight: Double
}

extension Expense: Equatable {

    static func == (lhs: Expense, rhs: Expense) -> Bool {
        return lhs.id == rhs.id
    }
}
