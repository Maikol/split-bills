//
//  ParticipantEditModel.swift
//  split-bills
//
//  Created by Carlos DeElias on 17/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

struct ParticipantEditModel: Identifiable, Equatable, Hashable {

    let id = UUID()
    let index: Int
    var name = ""
    var removed = false
}
