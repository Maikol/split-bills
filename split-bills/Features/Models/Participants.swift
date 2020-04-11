//
//  Participants.swift
//  split-bills
//
//  Created by Carlos DeElias on 7/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI
import Combine

final class ParticipantSelectionModel: ObservableObject {

    let participant: Participant
    @Published var isSelected: Bool

    init(participant: Participant, isSelected: Bool = true) {
        self.participant = participant
        self.isSelected = isSelected
    }
}

final class ParticipantEntryModel: ObservableObject {

    let participant: Participant
    @Published var amount: String

    init(participant: Participant, amount: String = "") {
        self.participant = participant
        self.amount = amount
    }
}
