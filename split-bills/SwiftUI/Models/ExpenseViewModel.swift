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

    // TODO: clean this up when moving to core data
    var id: Int64? = nil
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

        if splitEqually {
            return true
        }

        switch SplitTpe(index: splitTypeIndex) {
        case .equally:
            return selections.contains { $0.isSelected }
        case .amount:
            let doubleAmounts = amounts.compactMap { Double($0.amount) }
            let participantsAmount = doubleAmounts.reduce(0, +)
            return fabs(amount - participantsAmount) < 0.02
        }
    }

    init(participants: [Participant]) {
        self.participants = participants

        selections = participants.map { ParticipantSelectionModel(participant: $0) }
        amounts = participants.map { ParticipantEntryModel(participant: $0) }
    }
}

extension ExpenseViewModel.SplitTpe {

    init(index: Int) {
        guard let type = ExpenseViewModel.SplitTpe(rawValue: index) else {
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

extension ExpenseViewModel {

    func expense(with split: Split) -> Expense {
        guard let amount = Double(amount) else {
            fatalError("Trying to save an expense with no value")
        }

        let payer = split.participants[payerIndex]

        if splitEqually {
            return .equallySplited(with: split, payer: payer, participants: participants, description: description, amount: amount, id: id)!
        }

        switch SplitTpe(index: splitTypeIndex) {
        case .equally:
            let participating = selections.filter { $0.isSelected }.map { $0.participant }
            return .equallySplited(with: split, payer: payer, participants: participating, description: description, amount: amount, id: id)!
        case .amount:
            let participantsAmounts = amounts.compactMap { ($0.participant, Double($0.amount) ?? 0.0) }
            return Expense.splitByAmount(with: split, payer: payer, amounts: participantsAmounts, description: description, amount: amount, id: id)!
        }
    }
}

#if DEBUG
extension ExpenseViewModel {

    static let example = ExpenseViewModel(participants: [.init(name: "Bob"), .init(name: "Alice")])
}
#endif
