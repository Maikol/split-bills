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
        SplitDTO(id: 1, name: "Test 1", participants: participants, expenses: [expense1])
    ]
    
    static let participant1 = ParticipantDTO(name: "User 1")
    static let participant2 = ParticipantDTO(name: "User 2")
    static let participant3 = ParticipantDTO(name: "User 3")
    static let participant4 = ParticipantDTO(name: "User 4")

    static let participants = [participant1, participant2, participant3, participant4]

    static let expense1 = ExpenseDTO(id: 1, name: "Expense 1 test", payer: participant1, amount: 100.0, participantsWeight: participants.map { ExpenseWeightDTO(participant: $0, weight: 0.25) }, expenseType: .equallyWithAll)
}

enum DisplayModelMocks {
    static let participant1 = ParticipantDisplayModel(name: "User 1")
    static let participant2 = ParticipantDisplayModel(name: "User 2")
    static let participant3 = ParticipantDisplayModel(name: "User 3")
    static let participant4 = ParticipantDisplayModel(name: "User 4")

    static let participants = [participant1, participant2, participant3, participant4]
}
