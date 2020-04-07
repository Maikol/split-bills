//
//  Participants.swift
//  split-bills
//
//  Created by Carlos DeElias on 7/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct ParticipantSelectionModel: Identifiable, Hashable {

    let id = UUID()
    let name: String
    var isSelected = true

    init(name: String) {
        self.name = name
    }
}

struct ParticipantAmountModel: Identifiable, Hashable {

    let id = UUID()
    let name: String
    var amount = ""

    init(name: String) {
        self.name = name
    }
}

final class Participants: ObservableObject {

    @Published var selections: [ParticipantSelectionModel]
    @Published var amounts: [ParticipantAmountModel]

    init(names: [String]) {
        selections = names.map { ParticipantSelectionModel(name: $0) }
        amounts = names.map { ParticipantAmountModel(name: $0) }
    }
}
