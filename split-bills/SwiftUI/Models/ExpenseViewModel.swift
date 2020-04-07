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

        return true
    }

    init(participants: [Participant]) {
        self.participants = participants

        selections = participants.map { ParticipantSelectionModel(name: $0.name) }
        amounts = participants.map { ParticipantEntryModel(name: $0.name) }
    }
}

#if DEBUG
extension ExpenseViewModel {

    static let example = ExpenseViewModel(participants: [.init(name: "Bob"), .init(name: "Alice")])
}
#endif
