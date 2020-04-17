//
//  ExpenseTypeEditModel.swift
//  split-bills
//
//  Created by Carlos DeElias on 17/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

enum ExpenseTypeEditModel: Int, CaseIterable {

    struct Selection {
        let participant: ParticipantDisplayModel
        var isSelected = true
    }

    struct Amount {
        let participant: ParticipantDisplayModel
        var amount = ""
    }

    case equally
    case amount

    init(index: Int) {
        guard let type = ExpenseTypeEditModel(rawValue: index) else {
            fatalError("Index out of bounds \(index)")
        }

        self = type
    }

    var localized: String {
        switch self {
        case .equally: return NSLocalizedString("expenses.new.split-differently.equally", comment: "")
        case .amount: return NSLocalizedString("expenses.new.split-differently.amount", comment: "")
        }
    }
}
