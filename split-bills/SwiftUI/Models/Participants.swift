//
//  Participants.swift
//  split-bills
//
//  Created by Carlos DeElias on 7/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI
import Combine

struct ParticipantSelectionModel {

    let name: String
    var isSelected = true

    init(name: String) {
        self.name = name
    }
}

final class ParticipantEntryModel: ObservableObject {

    let name: String
    @Published var amount = ""

    init(name: String) {
        self.name = name
    }
}
