//
//  ExpenseViewModel.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 7/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Combine
import SwiftUI

final class ExpenseViewModel: ObservableObject {

    enum SplitTpe: Int, CaseIterable {
        case equally
        case amount
    }

    @Published var payerIndex = 0
    @Published var description = ""

    @Published var amount = "" {
        didSet {
            guard let amount = Double(amount) else { return }
            guard participants.count > 0 else {
                fatalError("Everything went wrong")
            }

            let amountByParticipant = (amount / Double(participants.count))
            for value in amounts {
                value.amount = String(format:"%.2f", amountByParticipant)
            }
        }
    }

    @Published var splitEqually = true
    @Published var splitTypeIndex = 0

    var participants: [Participant]
    @Published var selections: [ParticipantSelectionModel]
    @Published var amounts: [ParticipantEntryModel]

    var isValid: Bool {
        guard !description.isEmpty,
            let amount = Double(string: amount), amount > 0 else {
                return false
        }

        guard let splitType = SplitTpe(rawValue: splitTypeIndex) else {
            fatalError("This shouln't happen")
        }

        if splitEqually {
            return true
        }

        switch splitType {
        case .equally:
            return selections.contains { $0.isSelected }
        case .amount:
            let doubleAmounts = amounts.compactMap { Double($0.amount) }
            let participantsAmount = doubleAmounts.reduce(0, +)
            return fabs(amount - participantsAmount) < 0.01
        }
    }

    init(participants: [Participant]) {
        self.participants = participants

        selections = participants.map { ParticipantSelectionModel(participant: $0) }
        amounts = participants.map { ParticipantEntryModel(participant: $0) }
    }
}

extension ExpenseViewModel.SplitTpe {

    var localized: String {
        switch self {
        case .equally: return NSLocalizedString("expenses.new.split-differently.equally", comment: "")
        case .amount: return NSLocalizedString("expenses.new.split-differently.amount", comment: "")
        }
    }
}

#if DEBUG
extension ExpenseViewModel {

    static let example = ExpenseViewModel(participants: [.init(name: "Bob"), .init(name: "Alice")])
}
#endif
