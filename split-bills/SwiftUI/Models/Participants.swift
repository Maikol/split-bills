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
    @Published var isSelected = true

    init(participant: Participant) {
        self.participant = participant
    }
}

final class ParticipantEntryModel: ObservableObject {

    let participant: Participant
    @Published var amount = ""

    init(participant: Participant) {
        self.participant = participant
    }
}
