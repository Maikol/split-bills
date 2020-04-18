//
//  ExpenseWeightDisplayModel.swift
//  split-bills
//
//  Created by Carlos DeElias on 17/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

struct ExpenseWeightDisplayModel {

    let participant: ParticipantDisplayModel
    let weight: Double

    init(expenseWeight: ExpenseWeightDTO) {
        participant = .init(name: expenseWeight.participant.name)
        weight = expenseWeight.weight
    }
}
