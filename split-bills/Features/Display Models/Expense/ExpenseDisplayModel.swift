//
//  ExpenseDisplayModel.swift
//  split-bills
//
//  Created by Carlos DeElias on 17/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import SwiftUI

struct ExpenseDisplayModel: Identifiable {

    let id: Int64
    let name: String
    let payer: ParticipantDisplayModel
    let amount: Double
    let participantsWeight: [ExpenseWeightDisplayModel]

    init(expense: ExpenseDTO) {
        id = expense.id
        name = expense.name
        payer = .init(name: expense.payer.name)
        amount = expense.amount
        participantsWeight = expense.participantsWeight.map { .init(expenseWeight: $0) }
    }
}
