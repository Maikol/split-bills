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

struct Payment {

    let payer: Participant
    let receiver: Participant
    let amount: Double

    var description: String {
        return "\(payer.name) nees to pay \(amount) to \(receiver.name)"
    }
}

extension Expense: Equatable {

    static func == (lhs: Expense, rhs: Expense) -> Bool {
        return lhs.id == rhs.id
    }
}
