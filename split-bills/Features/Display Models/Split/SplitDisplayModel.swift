//
//  SplitDisplayModel.swift
//  split-bills
//
//  Created by Carlos DeElias on 17/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

struct SplitDisplayModel: Identifiable, Equatable {

    let id: Int64
    let name: String
    let participants: [ParticipantDisplayModel]

    init(split: SplitDTO) {
        id = split.id
        name = split.name
        participants = split.participants.map { .init(name: $0.name) }
    }

    var isValid: Bool {
        guard !name.isEmpty,
            let firstParticipant = participants.first, !firstParticipant.name.isEmpty,
            let secondParticipant = participants[safe: 1], !secondParticipant.name.isEmpty
        else {
                return false
        }

        return true
    }
}

#if DEBUG
extension SplitDisplayModel {
    static let example = SplitDisplayModel(split: .example)
}
#endif
