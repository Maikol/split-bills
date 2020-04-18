//
//  SplitEditModel.swift
//  split-bills
//
//  Created by Carlos DeElias on 17/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

struct SplitEditModel: Equatable, Builder {

    var name = ""
    var existingParticipants = [ParticipantEditModel]()
    var newParticipants = [ParticipantEditModel]()

    var isValid: Bool {
        let filteredParticipants = newParticipants.filter { !($0.name.isEmpty || $0.removed) }
        let participants = existingParticipants + filteredParticipants

        guard !name.isEmpty,
            let firstParticipant = participants.first, !firstParticipant.name.isEmpty,
            let secondParticipant = participants[safe: 1], !secondParticipant.name.isEmpty
        else {
            return false
        }

        return true
    }

    var activeNewParticipants: [ParticipantEditModel] {
        newParticipants.filter { !$0.removed }
    }

    init(split: SplitDTO? = nil) {
        split.map { split in
            name = split.name
            existingParticipants = split.participants.enumerated().map { ParticipantEditModel(index: $0.offset, name: $0.element.name) }
        }
    }

    func index(forNewParticipant participant: ParticipantEditModel) -> ParticipantEditModel.Index? {
        guard let index = activeNewParticipants.firstIndex(of: participant) else {
            return nil
        }

        return index + existingParticipants.count
    }
}
